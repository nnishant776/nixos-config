{ config, lib, pkgs, inputs, ... }:
let
  allUsers = [ config.conf.host.adminUser ] ++ config.conf.host.extraUsers;
  hmUsers = builtins.filter (u: u.enableHomeManager) allUsers;
  buildUser = import ../../lib/buildUser.nix;
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users = lib.listToAttrs (map (u:
      lib.nameValuePair u.name (buildUser {
        inherit pkgs lib;
        username = u.name;
        extraConfig = u.extraHomeConfig or {};
      })
    ) hmUsers);
  };
}
