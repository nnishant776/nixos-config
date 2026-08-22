{ config, lib, ... }: {
  config.services.flatpak.enable = lib.mkIf config.myconf.systemServices.flatpak.enable true;
}
