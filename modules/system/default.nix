{ config, pkgs, lib, ... }: {
  # Import package definitions
  imports = [
    ./settings
    ./packages
    ./desktop
  ];
}
