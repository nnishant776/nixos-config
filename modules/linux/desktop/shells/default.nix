{ pkgs, lib, config, ... }: {
  imports = [
    ./gnome.nix
    ./sway.nix
    ./hyprland
  ];
}
