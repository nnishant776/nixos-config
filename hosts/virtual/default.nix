{ config, pkgs, lib, ... }:
{
  conf = {
    profile = "workstation";

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
        vendor = "intel";
      };
      bootloader = {
        method = "bios";
      };
    };

    desktop = {
      environment = "hyprland";
      environments.hyprland.shell = "none";
    };

    development = {
      enable = true;
      sdk = {
        base.enable = true;
        cpp.enable = false;
      };
      tools = {
        opencode.enable = true;
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
