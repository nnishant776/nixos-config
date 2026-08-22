{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware.nix
    ./host.nix
    ./locale.nix
    ./fonts.nix
  ];

  networking.networkmanager.enable = lib.mkDefault config.myconf.systemServices.networking.enable;
  networking.wireless.enable = lib.mkDefault config.myconf.systemServices.networking.wifi.enable;
}
