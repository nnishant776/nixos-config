{ config, lib, ... }:
{
  config = lib.mkIf config.conf.sharing.enable {
    # Sharing implies the firewall.
    conf.networking.firewall.enable = lib.mkDefault true;
  };
}
