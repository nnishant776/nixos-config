{ pkgs, lib, config, ... }: {
  config = lib.mkIf config.myconf.desktop.enable {
    fonts = {
      fontconfig = {
        enable = true;
        antialias = true;
        defaultFonts = {
          serif = [ "Liberation Serif" ];
          sansSerif = [ "Liberation Sans Serif" ];
          monospace = [ "Liberation Mono" ];
        };
        hinting = {
          enable = true;
          style = "full";
        };
        includeUserConf = true;
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
      };
    };
  };
}
