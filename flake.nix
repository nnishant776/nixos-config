{
  description = "Multi-platform NixOS / Darwin configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  let
    lib = nixpkgs.lib;
    mkHost = import ./lib/mkHost.nix { inherit inputs; };
    mkUser = import ./lib/mkUser.nix { inherit inputs; };

    hostNames = builtins.attrNames (
      lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./hosts)
    );

    hostPlatforms = lib.genAttrs hostNames (h:
      let
        hostFile = import (./hosts + "/${h}/default.nix");
        raw = if builtins.isFunction hostFile then hostFile { config = {}; pkgs = {}; lib = lib; } else hostFile;
      in
        raw.nixpkgs.hostPlatform
    );

    linuxHosts = lib.filterAttrs (_: p: (lib.systems.elaborate p).isLinux) hostPlatforms;
    darwinHosts = lib.filterAttrs (_: p: (lib.systems.elaborate p).isDarwin) hostPlatforms;

    nixosConfigurations = lib.mapAttrs (h: _: mkHost { hostName = h; hostDir = ./hosts/${h}; }) linuxHosts;
    darwinConfigurations = lib.mapAttrs (h: _: mkHost { hostName = h; hostDir = ./hosts/${h}; }) darwinHosts;

    homeConfigurations = mkUser.mkHomeConfigurations {
      hostConfigs = nixosConfigurations // darwinConfigurations;
      usersDir = ./users;
    };

    customApps = lib.mapAttrs (system: _:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixosInstallScript = pkgs.writeShellScriptBin "os-install" ''
          set -euo pipefail

          if [ "$(uname)" = "Darwin" ]; then
            echo "Command not supported on this system"
            exit 1
          fi

          host="''${1:-}"

          if [ -z "$host" ]; then
            echo "usage: os-install <hostname>" >&2
            exit 1
          fi

          if [ -f /root/.disko-partitioning.done ]; then
            echo "warning: partitioning already done for host '$host', skipping disko" >&2
          else
            diskoScript="$(nix build --no-link --print-out-paths "${self}#nixosConfigurations.''${host}.config.system.build.diskoScript")"
            if "$diskoScript"; then
              touch /root/.disko-partitioning.done
              if [ ! "$(ls /dev/disk/by-partlabel/*swap*)" = "" ]; then
                swapon $(ls /dev/disk/by-partlabel/*swap*)
              fi
            else
              echo "error: disko partitioning failed for host '$host'" >&2
              exit 1
            fi
          fi

          nixos-install --root /mnt --flake "${self}#$host"

          # Clone the configuration so that the machine has a git revision
          # describing what it runs. Read in one eval, since each `nix eval`
          # against a host attribute evaluates that whole configuration.
          management="$(nix eval --json "${self}#nixosConfigurations.''${host}.config.conf.fleet")"
          repoUrl="$(printf '%s' "$management" | ${pkgs.jq}/bin/jq -r '.repo.url // ""')"
          repoRef="$(printf '%s' "$management" | ${pkgs.jq}/bin/jq -r '.repo.ref')"
          localPath="$(printf '%s' "$management" | ${pkgs.jq}/bin/jq -r '.localPath')"

          if [ -z "$repoUrl" ]; then
            echo "notice: host '$host' declares no upstream repository (conf.fleet.repo.url is null)" >&2
            echo "notice: leaving '$localPath' empty" >&2
            exit 0
          fi

          ${pkgs.git}/bin/git clone --branch "$repoRef" "$repoUrl" "/mnt''${localPath}"

          # self.rev only: self.dirtyRev carries a "-dirty" suffix and is not a
          # revision anything can be checked out to.
          installedRev="${self.rev or ""}"

          if [ -z "$installedRev" ]; then
            echo "WARNING: installed from a working tree with no commit (uncommitted changes), so there is no revision to pin to" >&2
            echo "WARNING: '$localPath' is left at the tip of '$repoRef' and may not match the system just installed" >&2
          else
            if ! ${pkgs.git}/bin/git -C "/mnt''${localPath}" checkout "$installedRev"; then
              echo "WARNING: revision '$installedRev' not found in '$repoUrl'; checkout is left at the tip of '$repoRef' and does NOT match the installed system; the machine will converge on the next sync" >&2
            fi
          fi

          finalRev="$(${pkgs.git}/bin/git -C "/mnt''${localPath}" rev-parse HEAD)"
          echo "checkout: path=/mnt''${localPath} ref=$repoRef rev=$finalRev"
        '';

        # No --impure here: the system configurations evaluate purely, and
        # passing it would hide a regression that `check-purity` exists to catch.
        nixFlakeSystemSwitch = pkgs.writeShellScriptBin "system-switch" ''
          set -euo pipefail

          host="''${1:-$(uname -n)}"
          flakePath="''${2:-/etc/nixos}"
          os="$(uname)"

          if [ ! -e "$flakePath/flake.nix" ]; then
            echo "system-switch: no flake at $flakePath" >&2
            echo "usage: system-switch [hostname] [flake path]" >&2
            exit 1
          fi

          if [ "$os" = "Darwin" ]; then
            exec sudo nix run nix-darwin -- switch --flake "$flakePath#$host"
          else
            if grep -qi "nixos" /etc/os-release > /dev/null 2>&1; then
              exec sudo nixos-rebuild switch --flake "$flakePath#$host"
            else
              exec sudo nix run system-manager -- switch --flake "$flakePath#$host"
            fi
          fi
        '';

        # Resolves the current user and host in the shell, so that the flake
        # outputs stay pure. --impure is needed here, and only here, because a
        # user's own ~/.config/home-manager/home.nix lives outside the flake.
        nixFlakeHomeSwitch = pkgs.writeShellScriptBin "home-switch" ''
          set -euo pipefail

          user="''${1:-$(id -un)}"
          flakePath="''${2:-/etc/nixos}"
          host="''${3:-$(uname -n)}"

          if [ ! -e "$flakePath/flake.nix" ]; then
            echo "home-switch: no flake at $flakePath" >&2
            echo "usage: home-switch [username] [flake path] [host]" >&2
            exit 1
          fi

          target="$user@$host"

          keys="$(nix eval --impure --json "$flakePath#homeConfigurations" \
                    --apply builtins.attrNames 2>/dev/null \
                  | tr -d '[]"' | tr ',' '\n')"

          if ! printf '%s\n' "$keys" | grep -qxF "$target"; then
            # A system-managed home has no published configuration by design, so
            # say that rather than reporting a missing attribute.
            if nix eval "$flakePath#nixosConfigurations.$host.config.home-manager.users" \
                 --apply "u: u ? \"$user\"" 2>/dev/null | grep -q true; then
              echo "home-switch: '$user' has an organisation-managed home on '$host'," >&2
              echo "  so there is nothing for you to activate — a system rebuild does it." >&2
              echo "  Personal configuration goes through review into users/$user/." >&2
              echo "  Self-management is granted per user with" >&2
              echo "  conf.users.accounts.<user>.selfManagedHome = true." >&2
              exit 1
            fi

            echo "home-switch: $flakePath declares no home configuration '$target'" >&2
            echo "available:" >&2
            printf '  %s\n' $keys >&2
            exit 1
          fi

          exec nix run home-manager -- switch --flake "$flakePath#$target" --impure
        '';

        # Evaluates every system output without --impure, so that an impure read
        # added to a shared module fails here rather than in an automated
        # rebuild. This must never pass --impure itself.
        checkPurityScript = pkgs.writeShellScriptBin "check-purity" ''
          set -euo pipefail

          flakePath="''${1:-.}"

          failures=0
          checked=0

          for outputAttr in nixosConfigurations darwinConfigurations; do
            # Enumeration failing and the output simply being absent are
            # different things: a Linux-only configuration legitimately has no
            # darwinConfigurations, and reporting that as a failure — silently,
            # which is what swallowing stderr here would do — makes the guard
            # untrustworthy.
            # stdout only: nix writes warnings such as "Git tree is dirty" to
            # stderr, and folding those into this value turns each word of the
            # warning into a phantom host name. On failure the command is
            # re-run to capture the diagnostic.
            if ! enumeration="$(nix eval --json "''${flakePath}#''${outputAttr}" --apply builtins.attrNames 2>/dev/null)"; then
              enumerationError="$(nix eval --json "''${flakePath}#''${outputAttr}" --apply builtins.attrNames 2>&1 || true)"
              case "''${enumerationError}" in
                *"does not provide attribute"*)
                  echo "SKIP ''${outputAttr} (not present in ''${flakePath})"
                  ;;
                *)
                  echo "FAIL ''${outputAttr} (could not enumerate)"
                  echo "''${enumerationError}" >&2
                  failures=$((failures + 1))
                  ;;
              esac
              continue
            fi

            names="$(printf '%s' "''${enumeration}" | tr -d '[]"' | tr ',' '\n')"

            for name in ''${names}; do
              if [ -n "''${name}" ]; then
                target="''${outputAttr}.''${name}.config.system.build.toplevel.drvPath"
                checked=$((checked + 1))
                if output="$(nix eval --raw "''${flakePath}#''${target}" 2>&1)"; then
                  echo "PASS ''${outputAttr}.''${name}"
                else
                  echo "FAIL ''${outputAttr}.''${name}"
                  echo "''${output}" >&2
                  failures=$((failures + 1))
                fi
              fi
            done
          done

          if [ "''${failures}" -gt 0 ]; then
            echo "check-purity: ''${failures} target(s) failed to evaluate purely" >&2
            exit 1
          fi

          # A guard that checked nothing has not passed.
          if [ "''${checked}" -eq 0 ]; then
            echo "check-purity: found no system outputs to check in ''${flakePath}" >&2
            exit 1
          fi

          echo "check-purity: all ''${checked} system output(s) evaluate purely"
        '';

      in {
        os-install = {
          type = "app";
          program = "${nixosInstallScript}/bin/os-install";
        };
        system-switch = {
          type = "app";
          program = "${nixFlakeSystemSwitch}/bin/system-switch";
        };
        home-switch = {
          type = "app";
          program = "${nixFlakeHomeSwitch}/bin/home-switch";
        };
        check-purity = {
          type = "app";
          program = "${checkPurityScript}/bin/check-purity";
        };
      })
    (lib.groupBy (p: p) (lib.attrValues (linuxHosts // darwinHosts)));
  in {
    inherit nixosConfigurations darwinConfigurations homeConfigurations;
    apps = customApps;
  };
}
