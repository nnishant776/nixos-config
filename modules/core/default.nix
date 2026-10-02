{ config, pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
  lixpkgs = pkgs.lixPackageSets;

  # Which kind of system this configuration is being deployed to. Declared by
  # conf.platform and set by lib/mkHost.nix, rather than sniffed from the
  # evaluating machine.
  #
  # This used to read /etc/os-release and look for "nixos", which was wrong on
  # two counts: it forced every NixOS build to run with --impure, and it
  # described the machine doing the *evaluation* rather than the system being
  # *built* — so building a NixOS closure from a Mac or a CI runner would decide
  # the target was not NixOS and install Lix on it.
  isNixOS = config.conf.platform == "nixos";
in {
  imports = [
    ./base.nix
    ./development
  ];

  nix = {
    enable = true;
    # On NixOS, nix is part of the system closure already. Everywhere else
    # (nix-darwin, system-manager on a foreign distro) this configuration is
    # managing an externally installed nix, and we want Lix there.
    package = lib.mkIf (!isNixOS) lixpkgs.stable.lix;
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
