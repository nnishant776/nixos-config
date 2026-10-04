{ config, lib, ... }:
{
  config = {
    services = {
      upower.enable = lib.mkIf config.conf.hardware.power.enable true;
      tuned.enable = lib.mkIf config.conf.hardware.power.enable true;
    };
  };
}
