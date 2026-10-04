{ ... }: {
  imports = [
    ./base.nix
    ./intel.nix
    ./amd.nix
    ./nvidia.nix
  ];
}
