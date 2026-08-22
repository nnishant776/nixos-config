{ config, pkgs, lib, ... }: {
  imports = [
    ./git.nix
  ];

  home.stateVersion = if pkgs.stdenv.hostPlatform.isDarwin then "24.05" else "26.05";
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;
}
