{ config, pkgs, lib, ... }:
let
  brewCfg = config.conf.systemServices.homebrew;
in {
  networking.hostName = config.conf.host.name;
  system.stateVersion = 6;

  users.users = lib.listToAttrs (builtins.map (user: lib.nameValuePair user.name {
    home = "/Users/${user.name}";
    description = user.fullName;
  }) ([ config.conf.host.adminUser ] ++ config.conf.host.extraUsers));

  homebrew = lib.mkIf brewCfg.enable {
    enable = true;
    brews = brewCfg.brews;
    casks = brewCfg.casks;
    masApps = brewCfg.masApps;
    onActivation = brewCfg.onActivation;
  };
}
