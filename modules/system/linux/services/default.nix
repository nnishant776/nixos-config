{ ... }: {
  imports = [
    ./bootloader.nix
    ./networking.nix
    ./multimedia.nix
    ./graphics.nix
    ./power-management.nix
    ./flatpak.nix
    ./containerisation.nix
    ./virtualisation.nix
    ./sharing.nix
    ./auto-update.nix
  ];
}
