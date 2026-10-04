{ ... }: {
  imports = [
    ./host
    ./homebrew.nix
    ./containers.nix
    ./virtualisation.nix
    ./secrets.nix
  ];
}
