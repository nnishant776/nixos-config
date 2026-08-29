{ config, pkgs, lib, ... }:
{
  config = {
    boot.loader.${config.conf.systemServices.bootloader.program}.enable = true;
    boot.loader.efi.canTouchEfiVariables = config.conf.systemServices.bootloader.allowEFIVariableEdit;
  };
}
