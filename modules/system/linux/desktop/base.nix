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
    (chromium.override { enableWideVine = true; })

    # File browsers
    thunar
    nautilus
  ];
in {
  config = lib.mkIf config.conf.desktop.enable {
    environment.systemPackages =
      (if config.conf.desktop.packages != [] then config.conf.desktop.packages else defaultDesktopPackages)
      ++ config.conf.desktop.extraPackages;

    programs.chromium.enable = true;
  };
}
