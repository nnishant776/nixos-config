{ config, lib, ... }: {
  config.services.flatpak.enable = lib.mkIf config.conf.flatpak.enable true;
}
