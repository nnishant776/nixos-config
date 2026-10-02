{ inputs, pkgs, lib, config, ... }:
let
  cfg = config.conf.desktop;
  isHyprland = cfg.enable && cfg.environments.hyprland.enable;
in {
  config = lib.mkIf isHyprland {
    # Set OZONE env var by default
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Enable UWSM
    programs.uwsm.enable = true;

    # Enable Hyprland
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        xwayland = {
          enable = true;
        };
        portalPackage = pkgs.xdg-desktop-portal-hyprland;
      };
    };

    # Configure desktop portals
    xdg.portal = {
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gnome
      ];
      config = {
        hyprland = {
          default = [ "hyprland" "gtk" "lxqt" "gnome" ];
        };
      };
    };

    # Enable Greetd if no other shell provides a greeter
    services.greetd = lib.mkIf (cfg.environments.hyprland.shell == "none") {
      enable = true;
      settings = {
        default_session = {
          command = lib.concatStringsSep " " ([
            "${pkgs.tuigreet}/bin/tuigreet"
            "--time"
            # Unquoted on purpose: greetd splits this string into argv itself, so a
            # literal quote can end up inside the path it passes to tuigreet.
            # Store paths never contain spaces, so there is nothing to protect.
            "--sessions" "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
          ] ++ lib.optionals (cfg.defaultEnvironment == "hyprland" || cfg.defaultEnvironment == null) [
            "--cmd" "Hyprland"
          ]);
          user = "greeter";
        };
      };
    };

    # Configure Polkit agent
    systemd.user.services.hyprpolkitagent = lib.mkIf (cfg.environments.hyprland.shell == "none") {
      description = "Hyprland Polkit Authentication Agent";
      documentation = [ "https://github.com" ];

      # Start automatically as soon as Hyprland loads the graphical target
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # Install Hyprland applications
    environment.systemPackages = with pkgs; [
      # Desktop utilities
      kitty
      nwg-displays
      nwg-look
      wl-mirror
      wlr-randr
      gpu-screen-recorder

      # Configuration management dependencies
      lua
      luarocks
    ] ++ lib.optionals (cfg.environments.hyprland.shell == "none") [
      # App launchers
      wofi
      rofi
      hyprlauncher

      # Security and Auth
      hyprpolkitagent
      hyprlock

      # Desktop Utilities
      swaynotificationcenter
      waybar
      hyprpaper
      grim
      slurp
      hyprshot

      # Session management
      hypridle
      greetd
    ];
  };
}
