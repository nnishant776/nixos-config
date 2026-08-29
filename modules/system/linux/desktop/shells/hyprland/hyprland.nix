{ inputs, pkgs, lib, config, ... }:
let
  cfg = config.conf.desktop;
  isHyprland = cfg.enable && (cfg.environment == "hyprland" || cfg.environment == "all");
in {
  config = lib.mkIf isHyprland {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Enable Hyprland
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        xwayland = {
          enable = true;
        };
        portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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
