{ pkgs, lib, config, ... }:
let
  defaultDesktopPackages = with pkgs; [
    alacritty
    wl-clipboard
    brightnessctl
    playerctl
    pavucontrol
    chromium
    blueman
  ];
in {
  config = lib.mkIf config.myconf.desktop.enable {
    environment.systemPackages =
      (if config.myconf.desktop.packages != [] then config.myconf.desktop.packages else defaultDesktopPackages)
      ++ config.myconf.desktop.extraPackages;
  };
}
