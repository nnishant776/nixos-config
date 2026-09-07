{ pkgs, lib, config, ... }:
let
  defaultDesktopPackages = with pkgs; [
    # Terminal
    alacritty

    # Clipboard
    wl-clipboard

    # System Brightness
    brightnessctl

    # Media Controls
    playerctl

    # Networking and Hardware
    blueman
    pavucontrol

    # Internet Browsers
    widevine-cdm
    (chromium.override {
      enableWideVine = true;
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--ozone-platform-hint=auto"
        "--enable-features=WebRTCPipeWireCapturer,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo,AcceleratedVideoEncoder"
      ];
    })
    brave

    # File browsers
    thunar
  ];
in {
  config = lib.mkIf config.conf.desktop.enable {
    # Install desktop packages
    environment.systemPackages = (
      if config.conf.desktop.packages != [] then
        config.conf.desktop.packages
      else
        defaultDesktopPackages
    )
    ++ config.conf.desktop.extraPackages;

    # Configure chromium
    programs.chromium.enable = true;

    # Enable PolicyKit
    security = {
      polkit.enable = true;
    };

    # Enable desktop services
    services = {
      gvfs.enable = true;                   # GNOME Virtual File System
      displayManager.enable = true;         # Display manager support
      accounts-daemon.enable = true;        # User accounts DBus service
      pipewire = {
        enable = true;                      # Piperwire multimedia service
        alsa.enable = true;                 # Alsa audio plugin
        pulse.enable = true;                # PulseAudio plugin
        wireplumber = {
          enable = true;                    # Pipewire session and policy manager
        };
      };
    };

    # Configure desktop portal
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        lxqt.xdg-desktop-portal-lxqt
      ];
      config = {
        common = {
          default = [
            "gtk"
            "hyprland"
            "lxqt"
            "gnome"
            "kde"
          ];
        };
      };
    };

    # Configuration for QT apps
    qt = {
      enable = true;
      platformTheme = "gnome";    # Use Qt6 Configuration Tool to control theme styling
      style = "adwaita";          # Set a unified look
    };

    # systemd.user.services.polkit-gnome-authentication-agent-1 = {
    #   description = "polkit-gnome-authentication-agent-1";
    #   wantedBy = [ "graphical-session.target" ];
    #   wants = [ "graphical-session.target" ];
    #   after = [ "graphical-session.target" ];
    #   serviceConfig = {
    #     Type = "simple";
    #     ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    #     Restart = "on-failure";
    #     RestartSec = 1;
    #     TimeoutStopSec = 10;
    #   };
    # };
  };
}
