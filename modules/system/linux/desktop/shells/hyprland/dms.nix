{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.conf.desktop;
  isDMS = cfg.enable && cfg.environments.hyprland.enable && (cfg.environments.hyprland.shell == "dms");
in {
  config = lib.mkIf isDMS {
    programs = {
      dank-material-shell.enable = true;
    };

    services = {
      displayManager.dms-greeter = {
        enable = true;
        compositor.name = "hyprland";
        package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };

    security.pam.services.greetd = {
      fprintAuth = true;
      u2fAuth = true;
    };
  };
}
