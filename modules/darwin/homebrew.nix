{ config, lib, ... }:
let
  brewCfg = config.conf.homebrew;
in {
  homebrew = lib.mkIf brewCfg.enable {
    enable = true;
    brews = brewCfg.brews;
    casks = brewCfg.casks;
    masApps = brewCfg.masApps;
    onActivation = brewCfg.onActivation;
  };
}
