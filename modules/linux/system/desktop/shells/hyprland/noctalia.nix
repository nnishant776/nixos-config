{ pkgs, lib, inputs, config, ... }:
{
  config = lib.mkIf (config.system.desktop.environments.hyprland.shell == "noctalia") {
    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
    };
    environment.systemPackages = [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
