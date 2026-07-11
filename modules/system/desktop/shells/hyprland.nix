{ pkgs, lib, config, ... }: {
  options = {
    system.desktop.shells = {
      hyprland = {
        enable = lib.mkEnableOption "Enable Hyprland";
      };
    };
  };

  config = lib.mkIf config.system.desktop.shells.hyprland.enable {
    # Enable GDM login manager
    services.displayManager.gdm.enable = true;

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
    ];
  };
}
