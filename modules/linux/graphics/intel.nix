{ pkgs, lib, config, ... }:
let
  cfg = config.conf.hardware.graphics;
  gfxPackages = [
    pkgs.intel-media-driver
    pkgs.libva-vdpau-driver
    pkgs.libvdpau-va-gl
    pkgs.intel-compute-runtime
    pkgs.vpl-gpu-rt
    pkgs.libva-utils
  ];
in {
  config = lib.mkIf (cfg.enable && cfg.vendor == "intel") {
    hardware.graphics.extraPackages = gfxPackages;

    # Automatically export graphics runtime libraries to nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false) gfxPackages;

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  };
}
