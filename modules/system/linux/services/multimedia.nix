{ pkgs, lib, config, ... }:
let
  cfg = config.myconf.systemServices.multimedia;
  baseMultimediaPackages = with pkgs; [
    # Standard audio/video frameworks and plugins
    ffmpeg
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    dav1d
    x264
    x265
    libopenaptx
    libspatialaudio
    libmatroska

    # Media players
    vlc
    mpv
    celluloid

    # Audio libraries
    alsa-lib
    pipewire
    wireplumber
  ];

  selectedMultimediaPackages = baseMultimediaPackages ++ cfg.extraPackages;

in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = selectedMultimediaPackages;

    # Automatically export multimedia libraries via nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false) (
      selectedMultimediaPackages ++ cfg.nix-ldLibraries
    );
  };
}
