# Base user configuration baseline.
# Note: Local machine override (~/.config/home-manager/default.nix) is dynamically
# imported in ../../lib/buildUser.nix to prevent infinite recursion during imports evaluation.
{ config, pkgs, lib, ... }: {
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
  ];

  news.display = "silent";

  home = {
    stateVersion = "26.05";
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;
}
