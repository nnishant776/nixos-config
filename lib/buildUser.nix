# Canonical user environment module generator.
# Loaded by both OS-level Home-Manager (modules/user/home-manager.nix)
# and standalone Home-Manager (lib/mkUser.nix).
{ pkgs, lib ? pkgs.lib, username, extraConfig ? {} }:
let
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/${username}"
    else "/home/${username}";
  # Tier 4 override: local machine-specific custom configuration
  customConfig = homeDir + "/.config/home-manager/default.nix";
in {
  imports = [
    ../modules/user/default.nix
    extraConfig
  ] ++ lib.optionals (builtins.pathExists customConfig) [
    (import customConfig)
  ];

  home = {
    username = lib.mkDefault username;
    homeDirectory = lib.mkDefault homeDir;
  };
}
