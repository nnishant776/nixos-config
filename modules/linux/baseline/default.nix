{ ... }: {
  imports = [
    ./boot.nix
    ./environment.nix
    ./kernel.nix
    ./firmware.nix
    ./disk.nix
  ];
}
