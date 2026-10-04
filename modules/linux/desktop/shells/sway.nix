{ pkgs, lib, config, ... }:
let
  isSway = config.conf.desktop.enable && config.conf.desktop.environments.sway.enable;
in {
  config = lib.mkIf isSway {
    programs.sway = {
      enable = true;
      wrapperFeatures = {
        gtk = true;
      };
    };

    # The greeter lives in ../session.nix.

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
