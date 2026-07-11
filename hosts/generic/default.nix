{ config, pkgs, lib, ...}: {
  system = {
    settings = {
      hardware.graphics = {
        enable = true;
        vendor = "intel";
      };
      host = {
        name = "GENERIC";
        adminUser = {
          name = "admin";
          fullName = "Administrator";
          groups = [ "networkmanager" "wheel" ]
            ++ lib.optionals (config.system.packages.containerisation.enable) [
              "docker" "podman"
            ]
            ++ lib.optionals (config.system.settings.hardware.graphics.enable) [
              "video"
            ];

          # WARNING:
          # This should be updated before or after configuring the system
          initialHashedPassword = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
        };
        # extraUsers = [
        #   {
        #     name = "jdoe";
        #     fullName = "Jane Doe";
        #     groups = []
        #       ++ lib.optionals (config.system.settings.hardware.graphics.enable) [
        #         "video"
        #       ];
        #     initialHashedPassword = "$y$j9T$48YlwhWeHFURdXuZpt6DA1$mCaEmkdB97RRCPr53YQxqSTh8.UP.dWpqArjv182n3B";
        #   }
        # ];
      };
    };
    desktop = {
      enable = true;
      shell = "all";
    };
    packages = {
      fonts = {
        enable = true;
      };
      development = {
        editors = {
          neovim = true;
        };
      };
    };
  };

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "LiterationSerif Nerd Font" ];
        sansSerif = [ "LiterationSans Nerd Font" ];
        monospace = [ "LiterationMono Nerd Font" ];
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
}
