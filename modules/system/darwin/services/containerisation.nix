{ config, lib, pkgs, ... }:
let
  cfg = config.conf.systemServices.containerisation;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker
      podman
      docker-buildx
      docker-compose
      podman-compose
    ] ++ cfg.extraPackages;
  };
}
