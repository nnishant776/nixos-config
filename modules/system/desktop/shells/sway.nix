{ pkgs, lib, config, ... }: {
  options = {
    system.desktop.shells = {
      sway = {
        enable = lib.mkEnableOption "Enable SwayWM";
      };
    };
  };

  config = lib.mkIf config.system.desktop.shells.sway.enable {
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
