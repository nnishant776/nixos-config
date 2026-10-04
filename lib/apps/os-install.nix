{ pkgs, self }:
pkgs.writeShellApplication {
  name = "os-install";
  runtimeInputs = with pkgs; [ jq git age systemd ];
  text = ''
    if [ "$(uname)" = "Darwin" ]; then
      echo "Command not supported on this system"
      exit 1
    fi

    host="''${1:-}"

    if [ -z "$host" ]; then
      echo "usage: os-install <hostname>" >&2
      exit 1
    fi

    # Everything about the host this script needs, in one evaluation.
    facts="$(nix eval --json "${self}#nixosConfigurations.''${host}.config" --apply 'c: {
      luks = builtins.mapAttrs (_: d: d.device) c.boot.initrd.luks.devices;
      tpm2 = c.conf.hardware.boot.tpm2Unlock;
      secrets = c.conf.secrets.file != null;
      fleet = c.conf.fleet;
    }')"

    # An encrypted layout reads its passphrase from /tmp/disk.key (see
    # templates/disko-luks.nix). Ask once, before partitioning.
    if [ "$(printf '%s' "$facts" | jq '.luks | length')" -gt 0 ] && [ ! -s /tmp/disk.key ]; then
      read -r -s -p "LUKS passphrase for $host: " passphrase; echo
      read -r -s -p "Again: " passphrase2; echo
      if [ "$passphrase" != "$passphrase2" ]; then
        echo "error: passphrases differ" >&2
        exit 1
      fi
      (umask 077; printf '%s' "$passphrase" > /tmp/disk.key)
      unset passphrase passphrase2
    fi

    if [ -f /root/.disko-partitioning.done ]; then
      echo "warning: partitioning already done for host '$host', skipping disko" >&2
    else
      diskoScript="$(nix build --no-link --print-out-paths "${self}#nixosConfigurations.''${host}.config.system.build.diskoScript")"
      if "$diskoScript"; then
        touch /root/.disko-partitioning.done
        for swap in /dev/disk/by-partlabel/*swap*; do
          if [ -e "$swap" ]; then swapon "$swap"; fi
        done
      else
        echo "error: disko partitioning failed for host '$host'" >&2
        exit 1
      fi
    fi

    # No interactive root password: root is locked by the configuration
    # and administration goes through sudo.
    nixos-install --root /mnt --no-root-passwd --flake "${self}#$host"

    # TPM enrolment as a second unlock method; the passphrase stays as
    # the fallback. PCR 7 (Secure Boot state) only, so a kernel update
    # does not lock the machine out.
    if [ "$(printf '%s' "$facts" | jq -r '.tpm2')" = "true" ]; then
      if [ -e /sys/class/tpm/tpm0 ]; then
        mapfile -t luksDevices < <(printf '%s' "$facts" | jq -r '.luks[]')
        for dev in "''${luksDevices[@]}"; do
          echo "enrolling TPM2 on $dev"
          systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --unlock-key-file=/tmp/disk.key "$dev"
        done
      else
        # Not fatal: the crypttab option falls back to the passphrase at
        # boot, so the machine is still usable, just without the TPM.
        echo "warning: conf.hardware.boot.tpm2Unlock is set but this machine has no TPM2; skipping enrolment, the passphrase is the only unlock method" >&2
      fi
    fi
    rm -f /tmp/disk.key

    # A host with secrets gets its age key now, so its secrets can be
    # encrypted to it before the machine first boots. The public half is
    # what goes into .sops.yaml.
    if [ "$(printf '%s' "$facts" | jq -r '.secrets')" = "true" ]; then
      install -d -m 700 /mnt/var/lib/sops-nix
      if [ ! -s /mnt/var/lib/sops-nix/key.txt ]; then
        (umask 077; age-keygen -o /mnt/var/lib/sops-nix/key.txt 2>/dev/null)
      fi
      echo "age public key for $host (add to .sops.yaml): $(age-keygen -y /mnt/var/lib/sops-nix/key.txt)"
    fi

    # Clone the configuration so that the machine has a git revision
    # describing what it runs.
    repoUrl="$(printf '%s' "$facts" | jq -r '.fleet.repo.url // ""')"
    repoRef="$(printf '%s' "$facts" | jq -r '.fleet.repo.ref')"
    localPath="$(printf '%s' "$facts" | jq -r '.fleet.localPath')"

    if [ -z "$repoUrl" ]; then
      echo "notice: host '$host' declares no upstream repository (conf.fleet.repo.url is null)" >&2
      echo "notice: leaving '$localPath' empty" >&2
      exit 0
    fi

    git clone --branch "$repoRef" "$repoUrl" "/mnt''${localPath}"
    # Fleet machines pull. The push URL is made unusable so a stray push
    # from this checkout fails; the sync re-applies it on every run.
    git -C "/mnt''${localPath}" remote set-url --push origin no_push

    # self.rev only: self.dirtyRev carries a "-dirty" suffix and is not a
    # revision anything can be checked out to.
    installedRev="${self.rev or ""}"

    if [ -z "$installedRev" ]; then
      echo "WARNING: installed from a working tree with no commit (uncommitted changes), so there is no revision to pin to" >&2
      echo "WARNING: '$localPath' is left at the tip of '$repoRef' and may not match the system just installed" >&2
    else
      if ! git -C "/mnt''${localPath}" checkout "$installedRev"; then
        echo "WARNING: revision '$installedRev' not found in '$repoUrl'; checkout is left at the tip of '$repoRef' and does NOT match the installed system; the machine will converge on the next sync" >&2
      fi
    fi

    finalRev="$(git -C "/mnt''${localPath}" rev-parse HEAD)"
    echo "checkout: path=/mnt''${localPath} ref=$repoRef rev=$finalRev"
  '';
}
