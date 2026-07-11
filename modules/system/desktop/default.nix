{ pkgs, lib, config, ... }: {
  imports = [
    ./shells
    ./apps.nix
  ];

  options = {
    system.desktop = {
      enable = lib.mkEnableOption "Enable GUI Desktop";
      shell = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["gnome" "hyprland" "sway" "all" ]);
        default = null;
      };
    };
  };

  config = lib.mkIf config.system.desktop.enable {
    security = {
      polkit = {
        enable = true;
      };
    };

    services = {
      flatpak.enable = true;
      gvfs.enable = true; # Nautilus
      # devmon.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      tuned.enable = true;
      accounts-daemon.enable = true;
      gnome = {
        sushi.enable = true; # Sushi, a quick previewer for nautilus
        evolution-data-server.enable = true;
        glib-networking.enable = true;
        gnome-keyring.enable = true;
        gnome-online-accounts.enable = true;
      };
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = ["graphical-session.target"];
        wants = ["graphical-session.target"];
        after = ["graphical-session.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };

    system = {
      packages.multimedia.enable = true;
      desktop = {
        shells = {
          gnome.enable = config.system.desktop.shell == "gnome" || config.system.desktop.shell == "all";
          hyprland.enable = config.system.desktop.shell == "hyprland" || config.system.desktop.shell == "all";
          sway.enable = config.system.desktop.shell == "sway" || config.system.desktop.shell == "all";
        };
      };
    };
  };
}
