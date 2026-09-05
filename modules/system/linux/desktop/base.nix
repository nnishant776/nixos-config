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
        "--enable-features=AcceleratedVideoEncoder"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--enable-features=VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport"
        "--enable-features=UseMultiPlaneFormatForHardwareVideo"
      ];
    })
    brave

    # File browsers
    thunar
  ];
in {
  config = lib.mkIf config.conf.desktop.enable {
    environment.systemPackages =
      (if config.conf.desktop.packages != [] then config.conf.desktop.packages else defaultDesktopPackages)
      ++ config.conf.desktop.extraPackages;

    programs.chromium.enable = true;
  };
}
