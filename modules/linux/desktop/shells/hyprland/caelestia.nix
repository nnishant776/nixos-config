{ pkgs, lib, inputs, config, ... }:
let
  cfg = config.conf.desktop;
  isCaelestia = cfg.enable && cfg.environments.hyprland.enable && (cfg.environments.hyprland.shell == "caelestia");
in {
  config = lib.mkIf isCaelestia {
    environment.systemPackages = [
      inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
