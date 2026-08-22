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
  config = lib.mkIf config.myconf.desktop.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = fontPackages;

      fontconfig = {
        enable = true;
        antialias = true;
        defaultFonts = {
          serif = [ "Liberation Serif" ];
          sansSerif = [ "Liberation Sans Serif" ];
          monospace = [ "Liberation Mono" ];
        };
        hinting = {
          enable = true;
          style = "full";
        };
        includeUserConf = true;
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
      };
    };
  };
}
