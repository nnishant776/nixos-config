{ pkgs, lib, inputs, config, ... }:
let
  cfg = config.myconf.desktop;
  isNoctalia = cfg.enable && (cfg.environment == "hyprland" || cfg.environment == "all") && (cfg.environments.hyprland.shell == "noctalia");
in {
  config = lib.mkIf isNoctalia {
    programs = {
      noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };
      noctalia-greeter = {
        enable = true;
        settings = {
          session.default = "Hyprland (uwsm-managed)";
        };
      };
    };

    environment.systemPackages = [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
