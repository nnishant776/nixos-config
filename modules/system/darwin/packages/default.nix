{ config, pkgs, lib, ... }:
let
  basePackages = with pkgs; [
    neovim
    gnumake
    git
    curl
    file
    which
    tree
    procs
    btop
    dust
    ncdu
    zip
    xz
    zstd
    p7zip
    gnutar
    gnugrep
    gawk
    gnused
    jq
    fzf
    fd
    (ripgrep.override { withPCRE2 = true; })
    wget
    rsync
    openssl
  ];
in {
  imports = [
    ./development.nix
  ];

  environment.systemPackages = basePackages;
}
