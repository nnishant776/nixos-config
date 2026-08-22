{ config, pkgs, lib, ... }: {
  imports = [
    ./bootloader.nix
    ./services.nix
    ./settings
    ./packages
    ./desktop
  ];
}
