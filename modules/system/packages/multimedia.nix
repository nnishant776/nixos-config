{ pkgs, lib, config, ... }: {
  options = {
    system.packages.multimedia = {
      enable = lib.mkEnableOption "Enable installation of multimedia packages";
      base = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [
          # Standard audio/video frameworks and plugins
          pkgs.ffmpeg
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
          pkgs.gst_all_1.gst-plugins-ugly
          pkgs.dav1d
          pkgs.x264
          pkgs.x265
          pkgs.libopenaptx
          pkgs.libspatialaudio
          pkgs.libmatroska

          # Media players
          pkgs.vlc
          pkgs.mpv
          pkgs.celluloid

          # Other potential libraries
          pkgs.alsa-lib
          pkgs.pipewire
          pkgs.wireplumber
        ];
      };
    };
  };

  config = {
    environment.systemPackages = lib.mkIf config.system.packages.multimedia.enable
      config.system.packages.multimedia.base;
  };
}
