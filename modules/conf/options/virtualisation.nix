{ lib, ... }: {
  options.conf.virtualisation = {
    enable = lib.mkEnableOption "virtualisation (KVM, QEMU, libvirt, virt-manager)";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra virtualisation packages.";
    };
    nix-ldLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Runtime shared libraries exported to nix-ld for virtualisation.";
    };
  };
}
