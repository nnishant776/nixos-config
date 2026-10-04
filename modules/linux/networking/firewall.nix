{ config, lib, ... }:
let
  cfg = config.conf.networking;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.firewall.enable (lib.mkMerge [
      ({ enable = true; })
      (if cfg.firewall.config != {} then cfg.firewall.config else {})
      (if config.conf.sharing.ssh.enable then { allowedTCPPorts = [ 22 ]; } else {})
    ]);
  };
}
