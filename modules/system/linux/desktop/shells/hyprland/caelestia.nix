{ pkgs, lib, inputs, config, ... }:
let
  cfg = config.conf.desktop;
  isCaelestia = cfg.enable && (cfg.environment == "hyprland" || cfg.environment == "all") && (cfg.environments.hyprland.shell == "caelestia");
in {
  config = lib.mkIf isCaelestia {
    environment.systemPackages = [
      inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
