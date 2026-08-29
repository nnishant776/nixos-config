{ pkgs, lib, config, ... }:
let
  cfg = config.conf.systemServices.graphics;
  gfxPackages = {
    "intel" = [
      pkgs.intel-media-driver
      pkgs.libva-vdpau-driver
      pkgs.libvdpau-va-gl
      pkgs.intel-compute-runtime
      pkgs.vpl-gpu-rt
      pkgs.libva-utils
    ];
    "amd" = [
      pkgs.mesa
      pkgs.libva
    ];
    "nvidia" = [
    ];
  };

  selectedGfxPackages = (gfxPackages.${cfg.vendor} or []) ++ cfg.extraPackages;

in {
  config = lib.mkIf cfg.enable {
    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = selectedGfxPackages;
      };
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = (if cfg.vendor == "intel" then
        "iHD"
      else if cfg.vendor == "amd" then
        "amdgpu"
      else
        "nvidia"
      );
    };

    # Automatically export graphics runtime libraries to nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false) (
      selectedGfxPackages
      ++ cfg.nix-ldLibraries
      ++ [
        pkgs.libGL
        pkgs.libva
        pkgs.vulkan-loader
        pkgs.libgbm
        pkgs.libdrm
      ]
    );
  };
}
