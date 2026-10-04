# conf.networking.firewall.enable is three-state: null leaves the NixOS
# firewall at its default, which is on; true or false sets it explicitly. Ports
# are never listed here by hand — the service that owns a port opens it through
# its own openFirewall.
{ config, lib, ... }:
let
  cfg = config.conf.networking;
  headless = config.conf.machineType == "headless";
in {
  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkMerge [
      (lib.mkIf (cfg.firewall.enable != null) { enable = cfg.firewall.enable; })
      { logRefusedConnections = lib.mkDefault headless; }
      cfg.firewall.config
    ];

    assertions = [
      {
        assertion = !(config.conf.fleet.repo.url != null && cfg.firewall.enable == false);
        message = "conf.networking.firewall.enable = false is not allowed on a fleet host (conf.fleet.repo.url is set).";
      }
    ];
  };
}
