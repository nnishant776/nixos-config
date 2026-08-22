{ config, lib, ... }:
{
  config = {
    services = {
      udisks2.enable = true;
      upower.enable = lib.mkIf config.myconf.systemServices.powerManagement.enable true;
      tuned.enable = lib.mkIf config.myconf.systemServices.powerManagement.enable true;
    };
  };
}
