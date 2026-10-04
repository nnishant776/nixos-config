{ pkgs, lib, config, ... }:
let
  cfg = config.conf.hardware.graphics;
  gfxPackages = [
  ];
in {
  config = lib.mkIf (cfg.enable && cfg.vendor == "nvidia") {
    hardware.graphics.extraPackages = gfxPackages;

    # Automatically export graphics runtime libraries to nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false) gfxPackages;

    environment.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";
  };
}
