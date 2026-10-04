# Firmware updates for machines with a person at them; headless machines and
# guests take firmware from their platform instead.
{ config, lib, ... }:
let
  interactive = builtins.elem config.conf.machineType [ "laptop" "desktop" ];
in {
  config = {
    hardware.enableRedistributableFirmware = lib.mkDefault true;
    services.fwupd.enable = lib.mkDefault interactive;
  };
}
