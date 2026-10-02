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
      inherit hostPlatforms;
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

          exec nixos-install --root /mnt --flake "${self}#$host"
        '';

        nixFlakeSystemSwitch = pkgs.writeShellScriptBin "system-switch" ''
          set -euo pipefail

          host="''${1:-}"
          flakePath="''${2:-}"
          os="$(uname)"

          if [ -z "$host" ] || [ -z "$flakePath" ]; then
            echo "usage: system-switch <hostname> <flake path>" >&2
            exit 1
          fi

          if [ "$os" = "Darwin" ]; then
            exec sudo nix run nix-darwin -- switch --flake "$flakePath#$host" --impure
          else
            if grep -qi "nixos" /etc/os-release > /dev/null 2>&1; then
              exec sudo nixos-rebuild switch --flake "$flakePath#$host" --impure
            else
              exec sudo nix run system-manager -- switch --flake "$flakePath#$host" --impure
            fi
          fi
        '';

        # Resolves the two things that are properties of *this machine* rather
        # than of the flake: which user is switching, and which host they are
        # on. Both used to be evaluation-time lookups, which made the
        # homeConfigurations outputs impure and broke on Darwin.
        #
        # --impure is still required here, and only here: the user's own
        # ~/.config/home-manager/default.nix lives outside the flake, so their
        # home configuration cannot be reproduced from the flake alone. The
        # system configurations evaluate purely, which is what lets a rebuild be
        # verified against a git revision.
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
            echo "home-switch: $flakePath declares no home configuration '$target'" >&2
            echo "available:" >&2
            printf '  %s\n' $keys >&2
            exit 1
          fi

          exec nix run home-manager -- switch --flake "$flakePath#$target" --impure
        '';

        # Guards against regressing the purity of the system-level flake
        # outputs (nixosConfigurations / darwinConfigurations). A single
        # builtins.readFile or similar impure read in a shared module is
        # enough to make every host's evaluation require --impure again,
        # which silently breaks automated rebuilds. This never passes
        # --impure itself: its entire purpose is to fail when purity is
        # lost.
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
