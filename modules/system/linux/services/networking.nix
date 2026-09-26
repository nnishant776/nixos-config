{ config, lib, ... }:
let
  svcCfg = config.conf.systemServices;
  cfg = svcCfg.networking;
in {
  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = lib.mkDefault cfg.enable;
    networking.wireless.enable = lib.mkDefault cfg.wifi.enable;
    networking.firewall = lib.mkIf cfg.firewall.enable (lib.mkMerge [
      ({ enable = true; })
      (if cfg.firewall.config != {} then cfg.firewall.config else {})
    ]);
  };
}
