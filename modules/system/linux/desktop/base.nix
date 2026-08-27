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
  config = lib.mkIf config.myconf.desktop.enable {
    environment.systemPackages =
      (if config.myconf.desktop.packages != [] then config.myconf.desktop.packages else defaultDesktopPackages)
      ++ config.myconf.desktop.extraPackages;

    programs.chromium.enable = true;
  };
}
