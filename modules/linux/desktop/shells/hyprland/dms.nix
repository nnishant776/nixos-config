{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.conf.desktop;
  isDMS = cfg.enable && cfg.environments.hyprland.enable && (cfg.environments.hyprland.shell == "dms");
in {
  config = lib.mkIf isDMS {
    programs = {
      dank-material-shell.enable = true;
    };

    # Applying an icon theme makes DMS run `pkill -HUP -f gtk`, which terminates
    # xdg-desktop-portal-gtk (../../portals.nix). systemd counts SIGHUP as a clean exit,
    # so without this it stays down and apps that follow the Settings portal (e.g.
    # Chromium) stop seeing the dark/light toggle until the next login.
    systemd.user.services.xdg-desktop-portal-gtk.serviceConfig.Restart = "always";

    # This module configures the DMS shell only. The login screen is regreet,
    # shared by every environment (../../greeter/) — the matching
    # dms-greeter is deliberately not used.
  };
}
