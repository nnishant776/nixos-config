{ config, lib, pkgs, inputs, ... }:
let
  allUsers = [ config.conf.host.adminUser ] ++ config.conf.host.extraUsers;
  hmUsers = builtins.filter (u: u.enableHomeManager) allUsers;
  buildUser = import ../../lib/buildUser.nix;
  flakeLib = import ../../lib/flakeLib.nix { inherit lib; };
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs flakeLib; };

    # Move a user's drifted file aside rather than aborting activation, tagged
    # with the flake revision that displaced it. A static extension makes the
    # SECOND conflict on the same file fail ("would be clobbered by backing up"),
    # which would leave a drifted user unable to be reconciled at all.
    backupFileExtension = "bak-${inputs.self.shortRev or inputs.self.dirtyShortRev or "unknown"}";
    users = lib.listToAttrs (map (u:
      lib.nameValuePair u.name (buildUser {
        inherit pkgs lib;
        username = u.name;
        extraModules = [ u.extraHomeConfig ];
        # allowLocalOverride is left at its default of false: this module tree is
        # evaluated by root during a system rebuild, and making the result depend
        # on a user-writable file outside the flake would also mean the same
        # flake revision no longer produces the same closure on every machine.
      })
    ) hmUsers);
  };
}
