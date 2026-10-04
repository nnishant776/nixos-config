{ config, ... }:
{
  networking.hostName = config.conf.host.name;
  system.stateVersion = 6;
}
