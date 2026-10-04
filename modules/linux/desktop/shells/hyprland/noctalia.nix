{ pkgs, lib, inputs, config, ... }:
let
  cfg = config.conf.desktop;
  isNoctalia = cfg.enable && cfg.environments.hyprland.enable && (cfg.environments.hyprland.shell == "noctalia");
in {
  config = lib.mkIf isNoctalia {
    programs = {
      noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };
    };

    # The cache is trusted only where its packages are used.
    nix.settings = {
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
    };

    environment.systemPackages = [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
