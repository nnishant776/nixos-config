{ ... }: {
  imports = [
    ./shells
    ./session.nix
    ./portals.nix
    ./audio.nix
    ./services.nix
    ./packages.nix
    ./printing.nix
    ./idle.nix
    ./fonts.nix
  ];
}
