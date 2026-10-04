{ inputs, pkgs, lib, config, flakeLib, ... }:
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
  # flakeLib.mkDefaults marks every scalar below as a default, so a host can
  # override any of them with a plain assignment. It leaves lists alone, so
  # fonts.packages must stay a plain value here rather than mkDefault:
  # modules/common/development/fonts.nix also contributes to it, and defaulting
  # either side would silently drop the other's packages. fontconfig.defaultFonts
  # entries are wrapped in mkDefault deliberately, since those are
  # priority-ordered preference lists where a host should replace rather than
  # concatenate.
  config = lib.mkIf config.conf.desktop.enable (flakeLib.mkDefaults {
    fonts = {
      fontDir.enable = true;
      enableDefaultPackages = true;
      packages = fontPackages;
      fontconfig = {
        enable = true;
        antialias = true;
        defaultFonts = {
          serif = lib.mkDefault [ "NotoSerif Nerd Font" ];
          sansSerif = lib.mkDefault [ "NotoSans Nerd Font" ];
          monospace = lib.mkDefault [ "NotoSansM Nerd Font" ];
          emoji = lib.mkDefault [ "Noto Color Emoji" ];
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
  });
}
