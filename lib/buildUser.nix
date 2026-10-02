# Canonical user environment module generator, used by lib/mkUser.nix.
#
# There is no system-level counterpart: the system does not activate Home
# Manager, because two generations cannot share one home directory. The user
# owns their home and activates it themselves; this flake supplies the
# organisation policy that their configuration merges with.
#
# Layers, in the order they are imported:
#   1. modules/user/           organisation baseline (declares values with mkDefault)
#   2. users/<username>/       organisation per-user config, auto-discovered
#   3. extraModules            host-declared conf.host.*.extraHomeConfig
#   4. ~/.config/home-manager  the user's own config — STANDALONE ONLY, never
#                              read during a system rebuild
#
# Import order is documentation only: the module system resolves conflicts by
# option priority (mkDefault 1000 > plain 100 > mkForce 50), never by position
# in this list. Treat these layers as a merge convention, not as a boundary an
# uncooperative user cannot cross.
{ pkgs
, lib ? pkgs.lib
, username
, extraModules ? [ ]
, usersDir ? ../users
  # Import the user's own ~/.config/home-manager/default.nix. Only lib/mkUser.nix
  # (standalone Home-Manager) sets this, where the user evaluates their own config
  # on their own machine. The system path must never enable it: a rebuild
  # evaluates as root, and the file belongs to the user.
, allowLocalOverride ? false
}:
let
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/${username}"
    else "/home/${username}";

  # Organisation-defined config for this user, tracked in the flake.
  orgConfig = usersDir + "/${username}/default.nix";

  # Machine-local config owned by the user, outside the flake.
  localConfig = homeDir + "/.config/home-manager/default.nix";
in {
  imports =
    [ ../modules/user/default.nix ]
    ++ lib.optional (builtins.pathExists orgConfig) orgConfig
    ++ extraModules
    ++ lib.optional (allowLocalOverride && builtins.pathExists localConfig) (import localConfig);

  home = {
    username = lib.mkDefault username;
    homeDirectory = lib.mkDefault homeDir;
  };
}
