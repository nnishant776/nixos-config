{ config, pkgs, lib, ... }: {
  imports = [
    ./base.nix
    ./host.nix
    ./locale.nix
    ./development
    ./services
    ./desktop
  ];
}
