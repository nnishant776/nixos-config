{ inputs, pkgs, lib, config, ... }:
let
  cfg = config.conf.desktop;
  isHyprland = cfg.enable && cfg.environments.hyprland.enable;
in {
  config = lib.mkIf isHyprland {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.uwsm.enable = true;

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

    # The greeter lives in ../../display-manager.nix.

    systemd.user.services.hyprpolkitagent = lib.mkIf (cfg.environments.hyprland.shell == "none") {
      description = "Hyprland Polkit Authentication Agent";
      documentation = [ "https://github.com" ];

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
    ];
  };
}
