{ config, lib, ... }:
{
  config = lib.mkMerge [
    {
      boot.loader.${config.conf.hardware.boot.loader}.enable = true;
      boot.loader.efi.canTouchEfiVariables = config.conf.hardware.boot.efiVariables;
    }

    (lib.mkIf (config.conf.hardware.boot.mode == "bios") {
      conf.hardware.boot.loader = lib.mkDefault "grub";
    })
  ];
}
