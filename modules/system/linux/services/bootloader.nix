{ config, pkgs, lib, ... }:
{
  config = {
    boot.loader.${config.myconf.systemServices.bootloader.program}.enable = true;
    boot.loader.efi.canTouchEfiVariables = config.myconf.systemServices.bootloader.allowEFIVariableEdit;
  };
}
