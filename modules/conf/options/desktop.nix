{ lib, ... }:
let
  packageList = desc: lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = desc;
  };
in {
  options.conf.desktop = {
    enable = lib.mkEnableOption "a graphical desktop and the ReGreet login screen";

    environments = {
      gnome.enable = lib.mkEnableOption "the GNOME desktop environment";
      hyprland = {
        enable = lib.mkEnableOption "the Hyprland desktop environment";
        shell = lib.mkOption {
          type = lib.types.enum [ "none" "caelestia" "noctalia" "dms" ];
          default = "none";
          description = "Desktop shell to run on Hyprland, or `none` for a bare compositor.";
        };
      };
      sway.enable = lib.mkEnableOption "the Sway desktop environment";
    };

    packages = packageList "Replaces the curated default set of desktop applications.";
    extraPackages = packageList "Appended to whichever set `packages` resolves to.";

    fonts = {
      packages = packageList "Replaces the curated default set of fonts.";
      extraPackages = packageList "Appended to whichever set `fonts.packages` resolves to.";
    };

    multimedia = {
      enable = lib.mkEnableOption "the audio and video stack (codecs, players)";
      extraPackages = packageList "Extra audio and video packages.";
      nix-ldLibraries = packageList "Runtime shared libraries exported to nix-ld for audio and video.";
    };
  };
}
