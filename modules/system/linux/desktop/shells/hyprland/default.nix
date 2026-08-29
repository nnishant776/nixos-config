{ inputs, pkgs, lib, config, ... }: {
  imports = [
    ./hyprland.nix
    ./caelestia.nix
    ./noctalia.nix
    ./dms.nix
  ];
}
