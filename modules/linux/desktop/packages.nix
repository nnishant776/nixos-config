{ pkgs, lib, config, ... }:
let
  defaultDesktopPackages = with pkgs; [
    # Terminal
    alacritty

    # Clipboard
    wl-clipboard

    # Hardware control
    brightnessctl
    libinput

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

    # Curosr
    phinger-cursors
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

    environment.sessionVariables = {
      XCURSOR_THEME = "phinger-cursors-dark"; # or "phinger-cursors-light"
      XCURSOR_SIZE = "24";
    };

    # Configure chromium
    programs.chromium.enable = true;
  };
}
