{ ... }: {
  imports = [
    ./shells
    ./session.nix
    ./portals.nix
    ./audio.nix
    ./services.nix
    ./packages.nix
    ./fonts.nix
  ];
}
