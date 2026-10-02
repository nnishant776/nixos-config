{ config, pkgs, lib, ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";

  conf = {
    profile = "developer";

    host = {
      name = "generic";
      users = {
        admin = {
          fullName = "Administrator";
          email = "admin@example.com";
          privileged = true;
          initialHashedPassword = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
          # Self-managed: this is a personally-administered machine whose live
          # configuration already lives in ~/.config/home-manager. Without this
          # grant the system would activate the organisation's home instead and
          # that configuration would simply be ignored.
          #
          # On a fleet machine leave this off — the default — so the home is
          # organisation-managed and personal configuration goes through review
          # into users/<name>/.
          allowHomeManagement = true;
        };
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
      environments.hyprland = {
        enable = true;
        shell = "dms";
      };
    };

    development = {
      enable = true;
      sdk = {
        base.enable = true;
        cpp.enable = true;
        nix.enable = true;
        lua.enable = true;
        go = {
          enable = true;
          extraPackages = with pkgs; [
            gopls
          ];
        };
        rust.enable = false;
        python.enable = false;
        java.enable = false;
      };
      editors = {
        neovim.enable = true;
        emacs.enable = true;
      };
      tools = {
        gemini.enable = false;
        opencode.enable = true;
        rtk.enable = true;
      };
    };
  };
}
