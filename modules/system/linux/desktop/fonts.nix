{ inputs, pkgs, lib, config, ... }:
let
  fontPackages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-mono
    fira-code-symbols
    nerd-fonts.liberation
    nerd-fonts.symbols-only
    nerd-fonts.noto
    nerd-fonts.fira-mono
    nerd-fonts.fira-code
    inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro
    inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-mono
  ];
in {
  config = lib.mkIf config.conf.desktop.enable {
    fonts = {
      fontDir.enable = true;
      enableDefaultPackages = true;
      packages = fontPackages;
      fontconfig = {
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
