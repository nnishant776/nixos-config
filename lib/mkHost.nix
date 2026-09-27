{ inputs }:
{ hostName, hostDir }:
let
  lib = inputs.nixpkgs.lib;
  hostFile = import (hostDir + "/default.nix");
  rawHost = if builtins.isFunction hostFile then hostFile { config = {}; pkgs = {}; lib = lib; } else hostFile;
  system = rawHost.nixpkgs.hostPlatform;
  sysElaborate = lib.systems.elaborate system;
  isLinux = sysElaborate.isLinux;
  isDarwin = sysElaborate.isDarwin;

  hardwareCfgPath =
    let perHost = hostDir + "/hardware-configuration.nix";
    in
      if builtins.pathExists perHost
      then [ perHost ]
      else [];

  diskoCfgPath =
    let perHost = hostDir + "/disko-config.nix";
    in
      if builtins.pathExists perHost
      then perHost
      else null;

  flakeLib = import ./flakeLib.nix { inherit lib; };

  commonModules = [
    (hostDir + "/default.nix")
    ../modules/core
    ../modules/conf
    ../modules/user/home-manager.nix
  ];
in
  if isLinux then
    inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { system.stateVersion = "26.05"; }
      ]
      ++ hardwareCfgPath
      ++ lib.optionals (diskoCfgPath != null) [ diskoCfgPath ]
      ++ [
        ../modules/system/linux
        inputs.home-manager.nixosModules.home-manager
        inputs.noctalia.nixosModules.default
        inputs.noctalia-greeter.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.dms.nixosModules.dank-material-shell
      ];
      specialArgs = { inherit inputs flakeLib; };
    }
  else if isDarwin then
    inputs.nix-darwin.lib.darwinSystem {
      modules = commonModules ++ [
        ../modules/system/darwin
        inputs.home-manager.darwinModules.home-manager
      ];
      specialArgs = { inherit inputs flakeLib; };
    }
  else
    builtins.throw "mkHost: unsupported system '${system}' for host '${hostName}'"
