{ pkgs, lib, ... }:
let
  basePackages = import ./base-packages.nix { inherit pkgs; };
in {
  environment.systemPackages = [
    pkgs.bash
  ] ++ basePackages;
}
