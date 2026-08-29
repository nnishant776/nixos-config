{ pkgs, lib, config, ... }:
let
  isGnome = config.conf.desktop.enable && (config.conf.desktop.environment == "gnome" || config.conf.desktop.environment == "all");
in {
  config = lib.mkIf isGnome {
    # Enable GDM login manager
    services.displayManager.gdm.enable = true;

    # Enable GNOME
    services.desktopManager.gnome.enable = true;

    # Install GNOME specific applications
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      file-roller
      dconf-editor
      gnomeExtensions.appindicator
      gnomeExtensions.user-themes
      gnomeExtensions.light-style
    ];

    environment.gnome.excludePackages = with pkgs; [
      orca
      geary
      gnome-tour
      gnome-user-docs
      baobab
      epiphany
      gnome-contacts
      gnome-logs
      gnome-maps
      totem
      yelp
      gnome-software
    ];

    services = {
      gnome = {
        sushi.enable = true;
        evolution-data-server.enable = true;
        glib-networking.enable = true;
        gnome-keyring.enable = true;
        gnome-online-accounts.enable = true;
      };
    };
  };
}
