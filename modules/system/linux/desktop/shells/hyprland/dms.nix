{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.conf.desktop;
  isDMS = cfg.enable && cfg.environments.hyprland.enable && (cfg.environments.hyprland.shell == "dms");
in {
  config = lib.mkIf isDMS {
    programs = {
      dank-material-shell.enable = true;
    };

    # This module configures the DMS shell only. The login screen is regreet,
    # shared by every environment (../../display-manager.nix) — the matching
    # dms-greeter is deliberately not used.
  };
}
