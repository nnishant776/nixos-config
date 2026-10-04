{ config, lib, ... }:
{
  config = {
    services = {
      udisks2.enable = true;
      upower.enable = lib.mkIf config.conf.hardware.power.enable true;
      tuned.enable = lib.mkIf config.conf.hardware.power.enable true;
    };
  };
}
