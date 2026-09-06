{ inputs, pkgs, lib, config, ... }:
let
  cfg = config.conf.desktop;
  isHyprland = cfg.enable && (cfg.environment == "hyprland" || cfg.environment == "all");
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

    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
      config = {
        hyprland = {
          default = [ "hyprland" "gtk" "gnome" ];
        };
      };
    };

    services.greetd = lib.mkIf (cfg.environments.hyprland.shell == "none") {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # Install Hyprland applications
    environment.systemPackages = with pkgs; [
      # Desktop utilities
      kitty
      nwg-displays
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

      # Desktop Utilities
      swaynotificationcenter
      waybar
      hyprpaper
      grim
      slurp

      # Session management
      hyprshot
      hypridle
      hyprlock
      greetd
    ];
  };
}
