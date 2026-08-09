{ pkgs, lib, config, ... }:
let
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
    ];
    "nvidia" = [
    ];
  };

in {
  options = {
    system.settings.hardware = {
      graphics = {
        enable = lib.mkEnableOption "Enable graphics and acceleration";
        vendor = lib.mkOption {
          type = lib.types.str;
          default = "intel";
        };
      };
    };
  };

  config = lib.mkIf config.system.settings.hardware.graphics.enable {
    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = gfxPackages.${config.system.settings.hardware.graphics.vendor};
      };
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = (if config.system.settings.hardware.graphics.vendor == "intel" then
        "iHD"
      else if config.system.settings.hardware.graphics.vendor == "amd" then
        "amdgpu"
      else
        "nvidia"
      );
    };
  };
}
