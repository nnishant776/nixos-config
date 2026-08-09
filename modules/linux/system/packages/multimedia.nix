{ pkgs, lib, config, ... }: {
  options = {
    system.packages.multimedia = {
      enable = lib.mkEnableOption "Enable installation of multimedia packages";
      basePackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          # Standard audio/video frameworks and plugins
          ffmpeg
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-ugly
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

          # Other potential libraries
          alsa-lib
          pipewire
          wireplumber
        ];
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
      };
    };
  };

  config = {
    environment.systemPackages = lib.mkIf config.system.packages.multimedia.enable config.system.packages.multimedia.basePackages;
    # programs.nix-ld.libraries = lib.mkAfter (lib.optionals (config.system.packages.multimedia.enable) (with pkgs; [
    #       glib
    #       udev
    #       systemd
    #     ] ++ config.system.packages.multimedia.basePackages
    #   )
    # );
  };
}
