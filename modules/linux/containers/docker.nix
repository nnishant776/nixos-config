{ lib, config, ... }:
let
  cfg = config.conf.containers;
in {
  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      daemon.settings = {
        # Containers on the default bridge do not see each other; user-defined
        # networks (compose, k3d) are unaffected.
        icc = lib.mkDefault false;
        "no-new-privileges" = lib.mkDefault true;
        # Containers survive a daemon restart, which every sync causes.
        "live-restore" = lib.mkDefault true;
      };
    };
  };
}
