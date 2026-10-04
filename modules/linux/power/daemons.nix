{ config, lib, ... }:
{
  config = {
    services = {
      upower.enable = lib.mkIf config.conf.hardware.powerManagement.enable true;
      tuned.enable = lib.mkIf config.conf.hardware.powerManagement.enable true;
    };
  };
}
