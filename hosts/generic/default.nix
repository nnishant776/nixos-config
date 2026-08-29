{ config, pkgs, lib, ... }: {
  conf = {
    profile = "developer";

    host = {
      name = "GENERIC";
      adminUser = {
        name = "admin";
        fullName = "Administrator";
        email = "admin@example.com";
        groups = [ "networkmanager" "wheel" ];
        initialHashedPassword = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
      };
    };

    systemServices = {
      graphics = {
        enable = true;
        vendor = "intel";
      };
      containerisation.enable = false; # Explicit override
      virtualisation.enable = false;   # Explicit override
    };

    desktop = {
      enable = true;
      environment = "all";
      environments.hyprland.shell = "noctalia";
    };

    development = {
      enable = true;
      sdk = {
        base.enable = true;
        cpp.enable = true;
        nix.enable = true;
        lua.enable = true;
        go.enable = false;
        rust.enable = false;
        python.enable = false;
        java.enable = false;
      };
      editors = {
        neovim.enable = true;
        emacs.enable = true;
      };
      tools = {
        gemini.enable = true;
        opencode.enable = true;
        rtk.enable = true;
      };
    };
  };

  fonts.fontconfig = {
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
}
