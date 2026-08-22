{ config, lib, pkgs, inputs, ... }:
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
          (./.)
          (user.extraHomeConfig or {})
        ];
        home = {
          username = user.name;
          homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user.name}" else "/home/${user.name}";
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
}
