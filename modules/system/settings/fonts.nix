{ pkgs, lib, config, ... }: {
  config = lib.mkIf config.system.packages.fonts.enable {
    fonts = {
      fontconfig = {
        enable = true;
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
        };
      };
    };
  };
}
