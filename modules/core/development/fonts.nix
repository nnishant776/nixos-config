{ config, pkgs, lib, ... }:
let
  dev = config.conf.development;
  defaultFontPackages = with pkgs; [
    nerd-fonts.liberation
    nerd-fonts.symbols-only
    nerd-fonts.noto
    nerd-fonts.fira-mono
    nerd-fonts.fira-code
  ];
in {
  config = lib.mkIf dev.enable {
    fonts = {
      packages = (if dev.fonts.packages != [] then dev.fonts.packages else defaultFontPackages);
      fontDir.enable = lib.mkIf pkgs.stdenv.isLinux true;
      enableDefaultPackages = lib.mkIf pkgs.stdenv.isLinux true;
      fontconfig = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        antialias = true;
        defaultFonts = {
          serif = [ "NotoSerif Nerd Font" ];
          sansSerif = [ "NotoSans Nerd Font" ];
          monospace = [ "NotoSansM Nerd Font" ];
          emoji = [ "Noto Color Emoji" ];
        };
        hinting = {
          enable = true;
          autohint = true;
          style = "slight";
        };
        includeUserConf = true;
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
        useEmbeddedBitmaps = true;
      };
    };
  };
}
