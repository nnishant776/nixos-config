# Fonts that come with the development stack on either platform. The option
# lives under conf.desktop.fonts; the gate is still development.enable so that
# a Mac, which has no conf.desktop, keeps getting them. Whether that gate should
# become the desktop is a question for the hardening pass, not this one.
{ config, pkgs, lib, ... }:
let
  dev = config.conf.development;
  fontCfg = config.conf.desktop.fonts;
  defaultFontPackages = with pkgs; [
    nerd-fonts.liberation
    nerd-fonts.symbols-only
    nerd-fonts.noto
    nerd-fonts.fira-mono
    nerd-fonts.fira-code
  ];
in {
  config = lib.mkIf dev.enable {
    fonts.packages = (if fontCfg.packages != [] then fontCfg.packages else defaultFontPackages);
  };
}
