{ config, pkgs, lib, ... }: {
  imports = [
    ./settings
    ./services
  ];
}
