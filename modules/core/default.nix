{ config, pkgs, lib, ... }:
let
  filePath = "/etc/os-release";
  searchString = "nixos";
  fileContent = builtins.readFile filePath;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isNixOS = lib.strings.hasInfix (lib.strings.toLower searchString) (lib.strings.toLower fileContent);
  lixpkgs = pkgs.lixPackageSets;
in {
  imports = [
    ./base.nix
    ./development
  ];

  nix = {
    enable = true;
    package = lib.mkIf (isDarwin || !isNixOS) lixpkgs.stable.lix;
    gc = {
      automatic = true;
      dates = lib.mkIf isLinux "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };

  nixpkgs.overlays = [
    (final: prev: {
      inherit (prev.lixpkgs.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena;
    })
  ];
}
