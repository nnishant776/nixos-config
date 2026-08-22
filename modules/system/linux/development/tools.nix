{ pkgs, lib, config, ... }:
let
  dev = config.myconf.development;

  getPackages = group: defaultPkgs:
    (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  toolPackages =
    lib.optionals dev.tools.gemini.enable (getPackages dev.tools.gemini (with pkgs; [ nodejs_22 bun antigravity ]))
    ++ lib.optionals dev.tools.opencode.enable (getPackages dev.tools.opencode (with pkgs; [ opencode ]))
    ++ lib.optionals dev.tools.rtk.enable (getPackages dev.tools.rtk (with pkgs; [ rtk ]));
in {
  config = {
    environment.systemPackages = lib.optionals dev.enable toolPackages;

    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false && dev.enable) (
      lib.optionals dev.tools.gemini.enable (dev.tools.gemini.nix-ldLibraries ++ [
        pkgs.glib
        pkgs.ffmpeg
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-ugly
        pkgs.pipewire
        pkgs.wireplumber
        pkgs.alsa-lib
      ])
      ++ lib.optionals dev.tools.rtk.enable dev.tools.rtk.nix-ldLibraries
    );
  };
}
