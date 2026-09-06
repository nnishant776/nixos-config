{ config, lib, ... }:
let
  cfg = config.conf.systemServices.networking;
in {
  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = lib.mkDefault cfg.enable;
    networking.wireless.enable = lib.mkDefault cfg.wifi.enable;
  };
}
