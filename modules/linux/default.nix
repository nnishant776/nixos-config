{ ... }: {
  imports = [
    ./baseline
    ./host
    ./networking
    ./sharing
    ./containers
    ./virtualisation
    ./desktop
    ./graphics
    ./multimedia.nix
    ./power
    ./flatpak.nix
    ./development
    ./fleet
  ];
}
