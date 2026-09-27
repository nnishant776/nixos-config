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
  # override any of them with a plain assignment (hosts/virtual does exactly that
  # for hinting.style, which used to be a "conflicting definition values" error).
  #
  # It deliberately leaves lists alone, which is what fonts.packages wants:
  # modules/core/development/fonts.nix contributes to the same option and the two
  # sets have to concatenate. fontconfig.defaultFonts is the opposite case — these
  # are priority-ordered preference lists, where concatenating a host's choice
  # after ours would leave the effective font unchanged — so those are wrapped
  # explicitly to get replace-semantics.
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
