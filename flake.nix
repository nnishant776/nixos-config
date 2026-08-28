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

    hyprland = {
      url = "github:hyprwm/Hyprland/v0.55.4?submodules=true";
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
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  let
    lib = nixpkgs.lib;
    mkHost = import ./lib/mkHost.nix { inherit inputs; };

    hostNames = builtins.attrNames (
      lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./hosts)
    );

    hostMeta = lib.genAttrs hostNames (h:
      import (./hosts + "/${h}/meta.nix")
    );

    linuxHosts = lib.filterAttrs (_: m: (lib.systems.elaborate m.system).isLinux) hostMeta;
    darwinHosts = lib.filterAttrs (_: m: (lib.systems.elaborate m.system).isDarwin) hostMeta;

    osInstallApps = lib.mapAttrs (system: _:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        disko = inputs.disko.packages.${system}.disko;
        script = pkgs.writeShellScriptBin "os-install" ''
          set -euo pipefail
          host="$1"
          if [ -z "''${host:-}" ]; then
            echo "usage: os-install <hostname>" >&2
            exit 1
          fi
          diskoConfig="${self}/hosts/$host/disko-config.nix"
          if [ -f /root/.disko-partitioning.done ]; then
            echo "warning: partitioning already done for host '$host', skipping disko" >&2
          elif [ -f "$diskoConfig" ]; then
            ${disko}/bin/disko --mode disko "$diskoConfig"
          else
            echo "warning: no disko-config.nix for host '$host', skipping disko (falling back to hardware-configuration.nix)" >&2
          fi
          exec nixos-rebuild switch --flake "${self}#$host"
        '';
      in {
        os-install = {
          type = "app";
          program = "${script}/bin/os-install";
        };
      })
    (lib.groupBy (m: m.system) (lib.attrValues linuxHosts));
  in {
    nixosConfigurations = lib.mapAttrs (h: _: mkHost { hostName = h; hostDir = ./hosts/${h}; }) linuxHosts;
    darwinConfigurations = lib.mapAttrs (h: _: mkHost { hostName = h; hostDir = ./hosts/${h}; }) darwinHosts;
    apps = osInstallApps;
  };
}
