# The greeter belongs to the host, not to a desktop environment.
#
# ReGreet, run inside cage via greetd, is the only login manager this flake
# configures. It has no compositor affinity and builds its session list from
# XDG_DATA_DIRS at runtime (ReGreet's sysutil.rs explicitly handles the NixOS
# case where that variable is a store path), so one greeter serves every
# environment the host installs — X11 and Wayland alike. That variable is
# published system-wide from services.displayManager.sessionPackages and reaches
# the greeter through its PAM session.
#
# Enabling a greeter from inside each environment module, as this used to, meant
# a host offering two environments started two greeters, which race for the seat.
{ pkgs, lib, config, ... }:
let
  cfg = config.conf.desktop;

  enabled = builtins.filter (e: e.on) [
    { name = "gnome"; on = cfg.environments.gnome.enable; }
    { name = "hyprland"; on = cfg.environments.hyprland.enable; }
    { name = "sway"; on = cfg.environments.sway.enable; }
  ];

  # greetd starts no X server — it hands the chosen command to PAM on a VT — so
  # an X11 session's bare Exec= would have no display to run against. startx
  # brings up a server on the free VT and execs the session as its client.
  # ReGreet's upstream default for this is `startx /usr/bin/env`, which relies on
  # a PATH the greeter session does not have, hence the absolute store paths.
  #
  # Wired only when the host has an X server. Nothing this flake offers provides
  # an X11 session today — this nixpkgs' GNOME is Wayland-only and Hyprland and
  # Sway are Wayland by design — so the guard keeps xinit out of every closure
  # for a session list that would always be empty.
  hasX11 = config.services.xserver.enable;

  # Any of these alongside regreet means two greeters fighting over the seat.
  #
  # Paths are exact on purpose: lightdm lives under services.xserver, not
  # services.displayManager, and an `or false` on a misspelled path makes the
  # check silently vacuous rather than failing loudly. The two `or false` entries
  # below are genuinely optional — they come from flake inputs (dms-greeter from
  # nixpkgs, noctalia-greeter from its own input) that a host need not have.
  otherDisplayManagers = [
    config.services.displayManager.gdm.enable
    config.services.displayManager.sddm.enable
    config.services.xserver.displayManager.lightdm.enable
    (config.services.displayManager.dms-greeter.enable or false)
    (config.programs.noctalia-greeter.enable or false)
  ];
in {
  config = lib.mkIf cfg.enable {
    # programs.regreet sets services.greetd.enable and its
    # default_session.command (dbus-run-session + cage + regreet) with
    # lib.mkDefault, so enabling it is enough and a host can still override the
    # command. Customisation goes through that module's own options rather than
    # a conf.* wrapper: settings (freeform TOML -> /etc/greetd/regreet.toml),
    # extraCss, cageArgs, and theme/iconTheme/cursorTheme/font.
    programs.regreet.enable = true;

    # Defined as a whole `settings` value rather than
    # settings.commands.x11_prefix = lib.mkIf ..., because a property inside
    # freeform TOML data would serialise the override marker into the file.
    # Merges with the regreet module's own settings.GTK by key.
    programs.regreet.settings = lib.mkIf hasX11 {
      commands.x11_prefix = [
        "${pkgs.xorg.xinit}/bin/startx"
        "${pkgs.coreutils}/bin/env"
      ];
    };

    # Note: nothing here touches security.pam.services.greetd. Its fprintAuth and
    # u2f.enable default to services.fprintd.enable and security.pam.u2f.enable
    # respectively, so enabling either on a host reaches the login prompt on its
    # own.
    # The dms branch used to force both true, which stacked pam_fprintd into the
    # greeter's PAM chain on hosts with no fingerprint daemon.

    assertions = [
      {
        assertion = !(lib.any lib.id otherDisplayManagers);
        message =
          "conf.desktop: a second display manager is enabled alongside regreet,"
          + " and they will race for the seat. regreet is the only greeter this"
          + " flake configures (modules/system/linux/desktop/display-manager.nix);"
          + " environment modules must not enable one of their own.";
      }
    ];

    warnings = lib.optional (enabled == [ ])
      "conf.desktop.enable is set but no environment is enabled; this host offers no session to log into.";
  };
}
