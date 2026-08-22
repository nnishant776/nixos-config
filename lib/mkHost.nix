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
    in if builtins.pathExists perHost
       then perHost
       else null;

  commonModules = [
    (hostDir + "/default.nix")
    ../modules/core
    ../modules/myconf
    { nixpkgs.hostPlatform = system; }
    ../modules/home/home-manager.nix
  ];
in
  if isLinux then
    inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { system.stateVersion = "26.05"; }
      ]
      ++ lib.optional (hardwareCfgPath != null) hardwareCfgPath
      ++ [
        ../modules/system/linux
        inputs.home-manager.nixosModules.home-manager
        inputs.noctalia.nixosModules.default
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
