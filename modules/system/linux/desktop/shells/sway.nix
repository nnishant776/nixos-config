{ pkgs, lib, config, ... }:
let
  isSway = config.myconf.desktop.enable && (config.myconf.desktop.environment == "sway" || config.myconf.desktop.environment == "all");
in {
  config = lib.mkIf isSway {
    # Enable GDM login manager
    services.displayManager.gdm.enable = true;

    # Enable SwayWM
    programs.sway = {
      enable = true;
      wrapperFeatures = {
        gtk = true;
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    environment.systemPackages = with pkgs; [
      # App launchers
      wmenu
      wofi

      # Desktop utilities
      grim
      slurp
      swaybg
      swaynotificationcenter
      waybar
      wdisplays
      wl-mirror
      wlr-randr

      # Session management
      swayidle
      swaylock
    ];
  };
}
