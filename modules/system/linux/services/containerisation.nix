{ pkgs, lib, config, ... }:
let
  cfg = config.myconf.systemServices.containerisation;
in {
  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    environment.systemPackages = with pkgs; [
      docker-buildx
      docker-compose
      podman-compose
    ] ++ cfg.extraPackages;
  };
}
