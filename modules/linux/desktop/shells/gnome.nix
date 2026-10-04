{ pkgs, lib, config, ... }:
let
  isGnome = config.conf.desktop.enable && config.conf.desktop.environments.gnome.enable;
in {
  config = lib.mkIf isGnome {
    # The greeter lives in ../greeter/.
    services.desktopManager.gnome.enable = true;

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

    # Lock timing is the organisation's; appearance stays the user's. The keys
    # are locked so the setting cannot be turned off from the session.
    programs.dconf.profiles.user.databases = lib.mkIf (config.conf.desktop.idleLockSeconds > 0) [{
      settings = {
        "org/gnome/desktop/screensaver" = {
          lock-enabled = true;
          lock-delay = lib.gvariant.mkUint32 0;
        };
        "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 config.conf.desktop.idleLockSeconds;
      };
      locks = [
        "/org/gnome/desktop/screensaver/lock-enabled"
        "/org/gnome/desktop/screensaver/lock-delay"
        "/org/gnome/desktop/session/idle-delay"
      ];
    }];
  };
}
