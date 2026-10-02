{ config, lib, pkgs, inputs, ... }:
let
  hostCfg = config.conf.host;

  # Organisation-managed homes: this is the default, and the system activates
  # them on rebuild.
  #
  # Users who have been granted allowHomeManagement are excluded here and get a
  # published homeConfigurations entry instead (lib/mkUser.nix). The two sets are
  # disjoint by construction, which is the point: two Home-Manager generations
  # over one home directory delete each other's files, because each activation
  # walks the previous generation's manifest and removes anything the new one
  # does not declare.
  #
  # conf.host.enableHomeManager is the host-level switch: with it off, nothing
  # here manages any home and nothing is published either.
  hmUsers = lib.filterAttrs
    (_: u: hostCfg.enableHomeManager && !u.allowHomeManagement)
    hostCfg.users;

  ungrantable = lib.filterAttrs
    (_: u: u.allowHomeManagement && !hostCfg.enableHomeManager)
    hostCfg.users;
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
    users = lib.mapAttrs (username: u:
      buildUser {
        inherit pkgs lib username;
        extraModules = [ u.extraHomeConfig ];
        # allowLocalOverride is left at its default of false: this module tree is
        # evaluated by root during a system rebuild, and making the result depend
        # on a user-writable file outside the flake would also mean the same
        # flake revision no longer produces the same closure on every machine.
      }
    ) hmUsers;
  };

  warnings = lib.mapAttrsToList (username: _:
    "conf.host.users.${username} has allowHomeManagement = true but"
    + " conf.host.enableHomeManager is false, so the grant has no effect —"
    + " nothing manages that home and nothing is published for them."
  ) ungrantable;
}
