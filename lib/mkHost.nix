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
    ({ config, ... }:
    let
      allUsers = [ config.myconf.host.adminUser ] ++ config.myconf.host.extraUsers;
      hmUsers = builtins.filter (u: u.enableHomeManager) allUsers;
    in {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        users = lib.listToAttrs (map (user: lib.nameValuePair user.name (
          { pkgs, ... }: {
            imports = [
              ../modules/home
              (user.extraHomeConfig or {})
            ];
            home = {
              username = user.name;
              homeDirectory = if isDarwin then "/Users/${user.name}" else "/home/${user.name}";
            };
            programs.git = {
              settings.user = {
                name = lib.mkDefault user.fullName;
                email = lib.mkDefault (if user.email != "" then user.email else "${user.name}@localhost");
              };
            };
          }
        )) hmUsers);
      };
    })
  ];
in
  if isLinux then
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
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
      inherit system;
      modules = commonModules ++ [
        ../modules/system/darwin
        inputs.home-manager.darwinModules.home-manager
      ];
      specialArgs = { inherit inputs; };
    }
  else
    builtins.throw "mkHost: unsupported system '${system}' for host '${hostName}'"
