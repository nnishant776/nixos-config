# Installs a host from this flake onto a machine booted from installer media.
#
# The live ISO keeps its writable store and / on tmpfs, so anything built or
# downloaded there lives in RAM. Installing therefore happens in two steps that
# keep the system off the installer:
#
#   1. The host's disko script partitions, formats and mounts the disks at
#      /mnt; then the swap the layout declares is turned on, so the evaluation
#      in step 2 can spill to the new disk instead of exhausting RAM.
#   2. nixos-install builds and downloads straight into /mnt/nix/store, with
#      its scratch space on /mnt too, reusing whatever the ISO already holds.
#
# The host and the target disks come from flags or from pickers.
{ pkgs, self }:
pkgs.writeShellApplication {
  name = "os-install";
  runtimeInputs = with pkgs; [ jq fzf util-linux coreutils nixos-install-tools ];
  text = ''
    usage() {
      cat >&2 <<'EOF'
    usage: os-install [-H HOST] [-d [NAME=]DEVICE]... [--flake REF] [--yes]

      -H, --host HOST        host to install (a directory under hosts/)
      -d, --disk [NAME=]DEV  physical device for a disk in the host's layout;
                             NAME may be omitted when the layout has one disk
          --flake REF        flake to install from (default: the one running this)
      -y, --yes              do not ask for confirmation before erasing

    Anything not given as a flag is chosen from a list, when run in a terminal.
    Whether a firmware boot entry is written follows the host's
    conf.hardware.boot.efiVariables.
    EOF
      exit "''${1:-1}"
    }

    # Partitioning and installing both need root. On the NixOS ISO the default
    # user has passwordless sudo.
    if [ "$(id -u)" -ne 0 ]; then
      exec sudo "$0" "$@"
    fi

    # path: so Nix reads the store copy as a plain directory; a bare store path
    # is taken for a git repository, which root-owned store paths fail as.
    flake="path:${self}"
    host=""
    assumeYes=false
    confirm=""
    declare -A disks=()
    unnamedDisk=""

    while [ $# -gt 0 ]; do
      case "$1" in
        -H|--host)  host="''${2:?--host needs a value}"; shift 2 ;;
        -d|--disk)
          case "''${2:?--disk needs a value}" in
            *=*) disks["''${2%%=*}"]="''${2#*=}" ;;
            *)   unnamedDisk="$2" ;;
          esac
          shift 2 ;;
        --flake)    flake="''${2:?--flake needs a value}"; shift 2 ;;
        -y|--yes)   assumeYes=true; shift ;;
        -h|--help)  usage 0 ;;
        *)          echo "os-install: unknown argument '$1'" >&2; usage ;;
      esac
    done

    interactive=false
    [ -t 0 ] && [ -t 1 ] && interactive=true

    need() {  # need WHAT — fail when a value is missing and there is no terminal
      if ! $interactive; then
        echo "os-install: $1 not given, and there is no terminal to choose in" >&2
        usage
      fi
    }

    pick() {  # pick HEADER — a dropdown over stdin, printing the chosen line
      fzf --height=40% --layout=reverse --border --no-multi --header="$1" \
        || { echo "os-install: nothing chosen; nothing was changed" >&2; exit 1; }
    }

    if [ -z "$host" ]; then
      need "the host"
      host="$(nix eval --json "$flake#nixosConfigurations" --apply builtins.attrNames \
        | jq -r '.[]' | pick "Host to install from $flake")"
    fi

    # Everything about the host this needs, in one evaluation.
    facts="$(nix eval --json "$flake#nixosConfigurations.$host.config" --apply 'c: {
      disks = builtins.mapAttrs (_: d: d.device) c.disko.devices.disk;
      swap = map (s: s.device) c.swapDevices;
      bios = c.conf.hardware.boot.mode == "bios";
      luks = builtins.attrValues (builtins.mapAttrs (_: d: d.device) c.boot.initrd.luks.devices);
      tpm2 = c.conf.hardware.boot.tpm2Unlock;
      secrets = c.conf.secrets.file != null;
      repo = c.conf.fleet.repo.url;
    }')"

    mapfile -t declared < <(jq -r '.disks | keys[]' <<<"$facts")
    if [ "''${#declared[@]}" -eq 0 ]; then
      echo "os-install: host '$host' declares no disko layout (hosts/$host/disko-config.nix)" >&2
      exit 1
    fi

    if [ -n "$unnamedDisk" ]; then
      if [ "''${#declared[@]}" -ne 1 ]; then
        echo "os-install: '$host' declares disks ''${declared[*]}; name the one '$unnamedDisk' is for: -d NAME=$unnamedDisk" >&2
        exit 1
      fi
      disks["''${declared[0]}"]="$unnamedDisk"
    fi

    # The disk this installer booted from is never offered.
    bootMedium=""
    if src="$(findmnt -no SOURCE /iso 2>/dev/null)" && [ -n "$src" ]; then
      bootMedium="/dev/$(lsblk -no PKNAME "$src" | head -1)"
    fi

    for name in "''${declared[@]}"; do
      if [ -z "''${disks[$name]:-}" ]; then
        need "a device for disk '$name'"
        taken=" ''${disks[*]} $bootMedium "
        disks[$name]="$(lsblk --nodeps --noheadings --exclude 7,11 --output PATH,SIZE,TRAN,MODEL \
          | while read -r path rest; do
              case "$taken" in *" $path "*) ;; *) printf '%-14s %s\n' "$path" "$rest" ;; esac
            done \
          | pick "Device for disk '$name' of $host (it will be erased)" | cut -d' ' -f1)"
      fi
      if [ ! -b "''${disks[$name]}" ]; then
        echo "os-install: ''${disks[$name]} is not a block device" >&2
        exit 1
      fi
      if [ "''${disks[$name]}" = "$bootMedium" ]; then
        echo "os-install: ''${disks[$name]} is the installer's own boot medium" >&2
        exit 1
      fi
      # GRUB on BIOS installs to the device written in the layout, not to the
      # one chosen here, so the two must agree.
      if [ "$(jq -r '.bios' <<<"$facts")" = true ] \
         && [ "$(jq -r --arg n "$name" '.disks[$n]' <<<"$facts")" != "''${disks[$name]}" ]; then
        echo "os-install: '$host' boots with BIOS; set disko.devices.disk.$name.device to ''${disks[$name]} in its layout first" >&2
        exit 1
      fi
    done

    echo
    echo "Installing $host from $flake"
    for name in "''${!disks[@]}"; do
      echo "  $name -> ''${disks[$name]}  (ALL DATA ON IT WILL BE ERASED)"
    done
    if ! $assumeYes; then
      need "confirmation (or --yes)"
      read -r -p "Type the host name to continue: " confirm
      if [ "$confirm" != "$host" ]; then
        echo "os-install: not confirmed; nothing was changed" >&2
        exit 1
      fi
    fi

    # Step 1: the host's disko script with the chosen devices patched in.
    mapping="{}"
    for name in "''${!disks[@]}"; do
      mapping="$(jq -c --arg n "$name" --arg d "''${disks[$name]}" '. + {($n): $d}' <<<"$mapping")"
    done
    export OS_INSTALL_DISKS="$mapping" OS_INSTALL_FLAKE="$flake" OS_INSTALL_HOST="$host"
    # shellcheck disable=SC2016 # a Nix expression; its interpolations are for Nix, not bash
    diskoScript="$(nix build --impure --no-link --print-out-paths --expr '
      let
        flake = builtins.getFlake (builtins.getEnv "OS_INSTALL_FLAKE");
        host = flake.nixosConfigurations.''${builtins.getEnv "OS_INSTALL_HOST"};
        devices = builtins.fromJSON (builtins.getEnv "OS_INSTALL_DISKS");
        patched = host.extendModules { modules = [{
          disko.devices.disk = builtins.mapAttrs
            (_: device: { device = flake.inputs.nixpkgs.lib.mkForce device; }) devices;
        }]; };
      in patched.config.system.build.diskoScript')"

    # Wipes, formats and mounts at /mnt. An encrypted layout asks for its
    # passphrase here.
    "$diskoScript"

    # disko formats swap but its mount step leaves it off (its fs entries are
    # ordered by mount point, and swap has none), so turn on what the host
    # declares. The evaluation and build in step 2 can then page to the new
    # disk; on an encrypted layout the swap is inside LUKS.
    while read -r swap; do
      if [ -b "$swap" ] && ! swapon --show=NAME --noheadings | grep -qx "$(readlink -f "$swap")"; then
        if swapon "$swap"; then
          echo "os-install: swap on $swap"
        else
          echo "os-install: warning: could not turn on swap $swap; continuing in RAM only" >&2
        fi
      fi
    done < <(jq -r '.swap[]' <<<"$facts")

    # Step 2: build and download straight onto the new disk.
    nixos-install --flake "$flake#$host" --root /mnt --no-root-passwd --no-channel-copy

    swapoff --all || true

    echo
    echo "Installed $host. Remove the installer media and reboot. Then:"
    if [ "$(jq -r '.repo != null' <<<"$facts")" = true ]; then
      echo "  - On first boot with network, the machine clones its configuration into"
      echo "    /etc/nixos and starts syncing from it."
    fi
    if [ "$(jq -r '.tpm2' <<<"$facts")" = true ]; then
      echo "  - To unlock with the TPM as well as the passphrase (needs a TPM2 chip):"
      jq -r '.luks[] | "      sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 " + .' <<<"$facts"
    fi
    if [ "$(jq -r '.secrets' <<<"$facts")" = true ]; then
      echo "  - Add the machine's age key to .sops.yaml, then run sops updatekeys:"
      echo "      sudo age-keygen -y /var/lib/sops-nix/key.txt"
    fi
  '';
}
