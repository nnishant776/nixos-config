# Organisation baseline for every managed user.
#
# Values here use lib.mkDefault so that per-user organisation config
# (users/<name>/, extraHomeConfig) and, where permitted, the user's own config
# can override them instead of colliding. A plain assignment in this file makes
# any competing definition a "conflicting definition values" evaluation error.
#
# Note: the machine-local override (~/.config/home-manager/default.nix) is
# resolved in ../../lib/buildUser.nix rather than here, both to avoid infinite
# recursion while evaluating imports and because it is gated per user.
{ config, pkgs, lib, ... }: {
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
  ];

  news.display = lib.mkDefault "silent";

  home = {
    stateVersion = lib.mkDefault "26.05";
    enableNixpkgsReleaseCheck = lib.mkDefault false;
  };

  programs.home-manager.enable = lib.mkDefault true;
}
