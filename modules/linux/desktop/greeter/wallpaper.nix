# Background image for the login screen. The file is copied into the store so
# the greeter user can read it; ReGreet scales it to cover the screen. User
# avatars are not shown: ReGreet 0.3 reads only names and shells from
# AccountsService and has no widget for an icon.
{ config, lib, ... }:
let
  cfg = config.conf.desktop;
in {
  config = lib.mkMerge [
    # The organisation's wallpaper, kept next to this module. A host sets its
    # own path, or null for ReGreet's plain background.
    { conf.desktop.greeter.wallpaper = lib.mkDefault ./wallhaven-j5oy7m.jpg; }

    (lib.mkIf (cfg.enable && cfg.greeter.wallpaper != null) {
      # A plain value, not mkDefault: markers inside freeform TOML data would be
      # serialised into the file. A host wanting another fit uses lib.mkForce on
      # programs.regreet.settings.background.fit.
      programs.regreet.settings.background = {
        path = "${cfg.greeter.wallpaper}";
        fit = "Cover";
      };
    })
  ];
}
