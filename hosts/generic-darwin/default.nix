{ config, pkgs, lib, ... }: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  conf = {
    role = "developer";

    host.name = "generic-darwin";

    users.accounts.admin = {
      fullName = "Administrator";
      email = "admin@example.com";
    };

    homebrew.enable = false;

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
