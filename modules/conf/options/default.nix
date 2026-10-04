{ ... }: {
  imports = [
    ./host.nix
    ./users.nix
    ./hardware.nix
    ./networking.nix
    ./sharing.nix
    ./containers.nix
    ./virtualisation.nix
    ./desktop.nix
    ./development.nix
    ./flatpak.nix
    ./homebrew.nix
    ./fleet.nix
  ];
}
