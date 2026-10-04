# The greeter belongs to the host, not to a desktop environment. ReGreet,
# run inside cage via greetd, is the only login manager this flake configures
# and it serves every installed environment via XDG_DATA_DIRS. Environment
# modules must not enable a greeter of their own, or two would race for the
# seat.
{ pkgs, lib, config, ... }:
let
  cfg = config.conf.desktop;

  enabled = builtins.filter (e: e.on) [
    { name = "gnome"; on = cfg.environments.gnome.enable; }
    { name = "hyprland"; on = cfg.environments.hyprland.enable; }
    { name = "sway"; on = cfg.environments.sway.enable; }
  ];

  # commands.x11_prefix needs absolute store paths, since the greeter session
  # has no PATH for startx to resolve against. Wired only when the host has an
  # X server, so xinit stays out of closures that never need it.
  hasX11 = config.services.xserver.enable;

  # Any of these alongside regreet means two greeters fighting over the seat.
  # The two `or false` entries are genuinely optional: dms-greeter and
  # noctalia-greeter come from flake inputs a host need not have.
  otherDisplayManagers = [
    config.services.displayManager.gdm.enable
    config.services.displayManager.sddm.enable
    config.services.xserver.displayManager.lightdm.enable
    (config.services.displayManager.dms-greeter.enable or false)
    (config.programs.noctalia-greeter.enable or false)
  ];
in {
  config = lib.mkIf cfg.enable {
    programs.regreet.enable = true;

    # Set as a whole `settings` value rather than
    # settings.commands.x11_prefix = lib.mkIf ..., since a property inside
    # freeform TOML data would serialise the override marker into the file.
    programs.regreet.settings = lib.mkIf hasX11 {
      commands.x11_prefix = [
        "${pkgs.xorg.xinit}/bin/startx"
        "${pkgs.coreutils}/bin/env"
      ];
    };

    assertions = [
      {
        assertion = !(lib.any lib.id otherDisplayManagers);
        message =
          "conf.desktop: a second display manager is enabled alongside regreet,"
          + " and they will race for the seat. regreet is the only greeter this"
          + " flake configures (modules/linux/desktop/session.nix);"
          + " environment modules must not enable one of their own.";
      }
    ];

    warnings = lib.optional (enabled == [ ])
      "conf.desktop.enable is set but no environment is enabled; this host offers no session to log into.";
  };
}
