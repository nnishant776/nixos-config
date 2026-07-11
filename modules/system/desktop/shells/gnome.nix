{ pkgs, lib, config, ... }: {
  options = {
    system.desktop.shells = {
      gnome = {
        enable = lib.mkEnableOption "Enable GNOME shell";
      };
    };
  };

  config = lib.mkIf config.system.desktop.shells.gnome.enable {
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
  };
}
