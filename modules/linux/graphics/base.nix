{ pkgs, lib, config, ... }:
let
  cfg = config.conf.hardware.graphics;
in {
  config = lib.mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
    hardware.graphics.enable = true;
    hardware.graphics.extraPackages = cfg.extraPackages;

    # Automatically export graphics runtime libraries to nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false) (
      cfg.extraPackages
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
