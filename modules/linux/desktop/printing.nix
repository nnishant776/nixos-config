# Print to printers on the network without being a print server. CUPS listens
# on localhost only; cups-browsed discovers driverless printers; Avahi answers
# mDNS for that discovery but advertises nothing about this host. Avahi must
# receive UDP 5353 to hear replies, which is why its firewall port stays open.
{ config, lib, ... }:
let
  cfg = config.conf.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.printing.enable) {
    services.printing = {
      enable = lib.mkDefault true;
      listenAddresses = lib.mkDefault [ "localhost:631" ];
      openFirewall = lib.mkDefault false;
      browsed.enable = lib.mkDefault true;
    };
    services.avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      openFirewall = lib.mkDefault true;
      publish.enable = lib.mkDefault false;
    };
  };
}
