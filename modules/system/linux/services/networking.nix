{ config, lib, ... }: {
  networking.networkmanager.enable = lib.mkDefault config.conf.systemServices.networking.enable;
  networking.wireless.enable = lib.mkDefault config.conf.systemServices.networking.wifi.enable;
}
