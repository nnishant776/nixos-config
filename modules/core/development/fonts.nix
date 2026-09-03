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
  config.environment.systemPackages = lib.optionals dev.enable (
    (if dev.fonts.packages != [] then dev.fonts.packages else defaultFontPackages)
    ++ dev.fonts.extraPackages
  );
}
