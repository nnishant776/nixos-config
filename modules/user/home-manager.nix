{ config, lib, pkgs, inputs, ... }:
let
  hostCfg = config.conf.host;

  # Organisation-managed homes, activated by the system on rebuild. Users
  # granted allowHomeManagement are excluded here and get a published
  # homeConfigurations entry instead (lib/mkUser.nix): the two sets must stay
  # disjoint, since two Home Manager generations activating the same home
  # directory will delete each other's files.
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

    # Tagged with the flake revision so a second conflict on the same file
    # doesn't fail: a static extension would make that backup clash too.
    backupFileExtension = "bak-${inputs.self.shortRev or inputs.self.dirtyShortRev or "unknown"}";
    users = lib.mapAttrs (username: u:
      buildUser {
        inherit pkgs lib username;
        extraModules = [ u.extraHomeConfig ];
        # allowLocalOverride stays at its default of false: this tree is
        # evaluated by root during a system rebuild, so the result must not
        # depend on a user-writable file outside the flake.
      }
    ) hmUsers;
  };

  warnings = lib.mapAttrsToList (username: _:
    "conf.host.users.${username} has allowHomeManagement = true but"
    + " conf.host.enableHomeManager is false, so the grant has no effect —"
    + " nothing manages that home and nothing is published for them."
  ) ungrantable;
}
