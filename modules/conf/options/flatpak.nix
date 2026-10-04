{ lib, ... }: {
  options.conf.flatpak.enable = lib.mkEnableOption "Flatpak";
}
