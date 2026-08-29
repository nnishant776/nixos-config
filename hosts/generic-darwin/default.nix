{ config, pkgs, lib, ... }: {
  conf = {
    profile = "developer";

    host = {
      name = "GENERIC-DARWIN";
      adminUser = {
        name = "admin";
        fullName = "Administrator";
        email = "admin@example.com";
        enableHomeManager = true;
      };
    };

    systemServices = {
      homebrew = {
        enable = false;
      };
    };

    development = {
      enable = true;
      sdk = {
        base.enable = true;
        cpp.enable = true;
        nix.enable = true;
        lua.enable = true;
      };
      editors = {
        neovim.enable = true;
      };
      tools = {
        gemini.enable = true;
      };
    };
  };
}
