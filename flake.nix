{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.55.4?submodules=true";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock/v0.9.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    stylix = {
      url = "github:nix-community/stylix";
    };
  };

  outputs =  inputs@{ self, ... }:
    let
      lib = inputs.nixpkgs.lib;

      hosts = builtins.filter (x: x != null) (
        lib.mapAttrsToList (name: value: if (value == "directory") then name else null) (
          builtins.readDir ./hosts
        )
      );

      pkgs = import inputs.nixpkgs {
        config = {
          allowUnfree = true;
          allowUnfreePredicate = (_: true);
        };
      };

    in
      {
      # generate a nixos configuration for every host in ./hosts
      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host;
          value = lib.nixosSystem {
            modules = [
              { system.stateVersion = "26.05"; }
              (./hardware-configuration.nix)
              (./hosts + "/${host}")
              ./modules/system
              (./override.nix)
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.extraSpecialArgs = {
                  inherit pkgs;
                  inherit inputs;
                };
              }
            ];
            specialArgs = {
              inherit inputs;
            };
          };
        }) hosts
      );
    };
}
