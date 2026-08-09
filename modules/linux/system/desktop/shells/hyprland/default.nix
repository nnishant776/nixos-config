{ inputs, pkgs, lib, config, ... }: {
  imports = [
    ./hyprland.nix
    ./caelestia.nix
  ];
}
