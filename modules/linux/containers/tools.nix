{ pkgs, lib, config, ... }:
let
  cfg = config.conf.containers;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-buildx
      docker-compose
      podman-compose
    ] ++ cfg.extraPackages;
  };
}
