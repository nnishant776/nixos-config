{ pkgs, lib, config, ... }:
let
  isSway = config.conf.desktop.enable && config.conf.desktop.environments.sway.enable;
in {
  config = lib.mkIf isSway {
    # Enable SwayWM
    programs.sway = {
      enable = true;
      wrapperFeatures = {
        gtk = true;
      };
    };

    # The greeter lives in ../display-manager.nix and is shared by every
    # environment; this module only configures Sway itself.

    environment.systemPackages = with pkgs; [
      # App launchers
      wmenu
      wofi

      # Desktop utilities
      grim
      slurp
      swaybg
      swaynotificationcenter
      waybar
      wdisplays
      wl-mirror
      wlr-randr

      # Session management
      swayidle
      swaylock
    ];
  };
}
