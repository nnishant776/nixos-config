# What a laptop needs beyond the power daemons. thermald is Intel-only; the
# microcode flag from hardware-configuration.nix is the cheapest Intel signal.
{ config, lib, ... }:
{
  config = lib.mkIf (config.conf.machineType == "laptop") {
    services.thermald.enable = lib.mkDefault config.hardware.cpu.intel.updateMicrocode;
    hardware.sensor.iio.enable = lib.mkDefault true;
  };
}
