{ pkgs, lib, config, ... }:
let
  isSway = config.conf.desktop.enable && (config.conf.desktop.environment == "sway" || config.conf.desktop.environment == "all");
  swayConfig = pkgs.writeText "greetd-sway-config" ''
    # `-l` activates layer-shell mode. Notice that `swaymsg exit` will run after gtkgreet.
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; swaymsg exit"
    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
  '';
in {
  config = lib.mkIf isSway {
    # Enable SwayWM
    programs.sway = {
      enable = true;
      wrapperFeatures = {
        gtk = true;
      };
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.sway}/bin/sway --config ${swayConfig}";
        };
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    environment.etc."greetd/environments".text = ''
    sway
    fish
    bash
    startxfce4
    '';

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
