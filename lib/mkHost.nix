{ inputs }:
{ hostName, hostDir }:
let
  lib = inputs.nixpkgs.lib;
  meta = import (hostDir + "/meta.nix");
  system = meta.system;
  sysElaborate = lib.systems.elaborate system;
  isLinux = sysElaborate.isLinux;
  isDarwin = sysElaborate.isDarwin;

  hardwareCfgPath =
    let perHost = hostDir + "/hardware-configuration.nix";
    in
      if builtins.pathExists perHost
      then perHost
      else "/etc/nixos/hardware-configuration.nix";

  diskoCfgPath =
    let perHost = hostDir + "/disko-config.nix";
    in
      if builtins.pathExists perHost
      then perHost
      else null;

  commonModules = [
    ../overlays.nix
    (hostDir + "/default.nix")
    ../modules/core
    ../modules/conf
    { nixpkgs.hostPlatform = system; }
    ../modules/home/home-manager.nix
  ];
in
  if isLinux then
    inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { system.stateVersion = "26.05"; }
      ]
      ++ [ hardwareCfgPath ]
      ++ lib.optionals (diskoCfgPath != null) [ diskoCfgPath ]
      ++ [
        ../modules/system/linux
        inputs.home-manager.nixosModules.home-manager
        inputs.noctalia.nixosModules.default
        inputs.noctalia-greeter.nixosModules.default
        inputs.disko.nixosModules.disko
      ];
      specialArgs = { inherit inputs; };
    }
  else if isDarwin then
    inputs.nix-darwin.lib.darwinSystem {
      modules = commonModules ++ [
        ../modules/system/darwin
        inputs.home-manager.darwinModules.home-manager
      ];
      specialArgs = { inherit inputs; };
    }
  else
    builtins.throw "mkHost: unsupported system '${system}' for host '${hostName}'"
