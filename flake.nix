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

        nixFlakeHomeSwitch = pkgs.writeShellScriptBin "home-switch" ''
          set -euo pipefail

          user="''${1:-}"
          flakePath="''${2:-}"

          if [ -z "$user" ] || [ -z "$flakePath" ]; then
            echo "usage: home-switch <username> <flake path>" >&2
            exit 1
          fi

          exec nix run home-manager -- switch --flake "$flakePath#$user" --impure
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
      })
    (lib.groupBy (p: p) (lib.attrValues (linuxHosts // darwinHosts)));
  in {
    inherit nixosConfigurations darwinConfigurations homeConfigurations;
    apps = customApps;
  };
}
