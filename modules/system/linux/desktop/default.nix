{ pkgs, lib, config, ... }: {
  imports = [
    ./shells
    ./base.nix
    ./fonts.nix
  ];

  config = lib.mkIf config.conf.desktop.enable {
    security = {
      polkit.enable = true;
    };

    services = {
      gvfs.enable = true; # Nautilus
      accounts-daemon.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        wireplumber = {
          enable = true;
        };
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
