{ pkgs, lib, config, ... }:
let
  isGnome = config.conf.desktop.enable && config.conf.desktop.environments.gnome.enable;
in {
  config = lib.mkIf isGnome {
    # The greeter lives in ../display-manager.nix: it serves every installed
    # session, so it is selected per host rather than per environment.

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
