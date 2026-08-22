{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware.nix
    ./host.nix
    ./locale.nix
    ./fonts.nix
  ];

  # Use systemd-boot as the bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = lib.mkDefault config.myconf.systemServices.networking.enable;
  networking.wireless.enable = lib.mkDefault config.myconf.systemServices.networking.wifi.enable;
}
