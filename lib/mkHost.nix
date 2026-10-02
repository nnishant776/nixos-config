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

  # The hosts/ directory name and conf.host.name must match: both
  # `nixos-rebuild switch` (resolving #$(hostname)) and the <user>@<host-dir>
  # home configuration keys depend on it.
  hostIdentity = { config, ... }: {
    assertions = [
      {
        assertion = config.conf.host.name == hostName;
        message =
          "hosts/${hostName} declares conf.host.name = \"${config.conf.host.name}\"."
          + " The host directory name and conf.host.name must be identical:"
          + " `nixos-rebuild switch` resolves #$(hostname) and home"
          + " configurations are keyed <user>@${hostName}."
          + " Either rename the directory to hosts/${config.conf.host.name}"
          + " or set conf.host.name = \"${hostName}\".";
      }
    ];
  };

  # Home Manager is wired in here for organisation-managed homes. Users
  # granted conf.host.*.allowHomeManagement are excluded and get a published
  # homeConfigurations entry instead.
  commonModules = [
    (hostDir + "/default.nix")
    hostIdentity
    ../modules/core
    ../modules/conf
    ../modules/user/home-manager.nix
  ];
in
  if isLinux then
    inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        {
          system.stateVersion = "26.05";
          conf.platform = "nixos";
        }
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
        { conf.platform = "darwin"; }
        ../modules/system/darwin
        inputs.home-manager.darwinModules.home-manager
      ];
      specialArgs = { inherit inputs flakeLib; };
    }
  else
    builtins.throw "mkHost: unsupported system '${system}' for host '${hostName}'"
