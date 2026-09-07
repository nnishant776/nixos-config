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
    fonts.packages = (if dev.fonts.packages != [] then dev.fonts.packages else defaultFontPackages);
  };
}
