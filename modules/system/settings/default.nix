{ config, pkgs, ... }: {
  imports = [
    ./hardware.nix
    ./host.nix
    ./locale.nix
    ./fonts.nix
  ];

  # Use systemd-boot as the bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
