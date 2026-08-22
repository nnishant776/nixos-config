{ config, lib, ... }: {
  networking.networkmanager.enable = lib.mkDefault config.myconf.systemServices.networking.enable;
  networking.wireless.enable = lib.mkDefault config.myconf.systemServices.networking.wifi.enable;
}
