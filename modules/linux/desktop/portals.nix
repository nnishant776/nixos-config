{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.conf.desktop.enable {
    # Configure desktop portal
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome            # For light/dark mode detection
        lxqt.xdg-desktop-portal-lxqt
      ];
      config = {
        common = {
          default = [
            "gtk"
            "hyprland"
            "lxqt"
            "gnome"
            "kde"
          ];
        };
      };
    };

    # Configuration for QT apps
    qt = {
      enable = true;
      platformTheme = "gnome";    # Use Qt6 Configuration Tool to control theme styling
      style = "adwaita";          # Set a unified look
    };
  };
}
