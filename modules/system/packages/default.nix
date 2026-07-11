{ config, pkgs, lib, ... }: {
  # Import package definitions
  imports = [
    ./development.nix
    ./fonts.nix
    ./multimedia.nix
    ./containerisation.nix
    ./virtualisation.nix
  ];

  options = {
    system.packages.base = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.curl
        pkgs.git
        pkgs.vim
        pkgs.neovim
        pkgs.bash
        pkgs.firefox
        pkgs.jq
        pkgs.file
      ];
    };
  };

  config = {
    # Enable nix experimental features
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Include mandatory packages by default
    environment.systemPackages = with pkgs; [] ++ ( config.system.packages.base );
  };
}
