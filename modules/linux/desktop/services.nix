{ lib, config, ... }:
{
  config = lib.mkIf config.conf.desktop.enable {
    # Enable PolicyKit
    security = {
      polkit.enable = true;
    };

    # Enable desktop services
    services = {
      gvfs.enable = true;                   # GNOME Virtual File System
      displayManager.enable = true;         # Display manager support
      accounts-daemon.enable = true;        # User accounts DBus service
      udisks2.enable = true;                # Removable media automount
    };

    # Desktop implications.
    conf.desktop.multimedia.enable = lib.mkDefault true;
    conf.hardware.graphics.enable  = lib.mkDefault true;
    conf.hardware.powerManagement.enable     = lib.mkDefault true;
    conf.flatpak.enable            = lib.mkDefault true;
  };
}
