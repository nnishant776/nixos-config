{ config, lib, ... }: {
  config.services.flatpak.enable = lib.mkIf config.conf.systemServices.flatpak.enable true;
}
