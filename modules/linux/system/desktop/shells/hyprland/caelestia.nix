{ pkgs, lib, inputs, config, ... }:
{
  config = lib.mkIf (config.system.desktop.environments.hyprland.shell == "caelestia") {
    environment.systemPackages = [
      inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
