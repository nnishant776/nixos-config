# Agents for when this machine is itself a guest.
{ config, lib, ... }:
{
  config = lib.mkIf (config.conf.machineType == "vm") {
    services.qemuGuest.enable = lib.mkDefault true;
    services.spice-vdagentd.enable = lib.mkDefault config.conf.desktop.enable;
  };
}
