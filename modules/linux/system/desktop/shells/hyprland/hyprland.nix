{ inputs, pkgs, lib, config, ... }: {
  options = {
    system.desktop.environments = {
      hyprland = {
        enable = lib.mkEnableOption "Enable Hyprland";
        shell = lib.mkOption {
          type = lib.types.enum [ "none" "caelestia" "noctalia" ];
          default = "none";
          description = "Select an optional shell to install with Hyprland";
        };
      };
    };
  };

  config = lib.mkIf config.system.desktop.environments.hyprland.enable {
    # Enable GDM login manager
    services.displayManager.gdm.enable = true;
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland = {
        enable = true;
      };
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    # Install Sway specific applications
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
    ] ++ lib.optionals (config.system.desktop.environments.hyprland.shell == "none") [
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
    ];
  };
}
