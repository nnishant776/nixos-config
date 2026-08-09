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
    };

    # Install Sway specific applications
    environment.systemPackages = with pkgs; [
      # App launchers
      wmenu
      wofi

      # Desktop utilities
      grim
      hyprpaper
      kitty
      slurp
      hyprshot
      swaynotificationcenter
      waybar
      nwg-displays
      wl-mirror
      wlr-randr
      hyprlauncher

      # Session management
      hypridle
      hyprlock

      # Configuration management dependencies
      lua
      luarocks
    ];
  };
}
