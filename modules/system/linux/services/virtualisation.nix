{ pkgs, lib, config, ... }:
let
  cfg = config.myconf.systemServices.virtualisation;
  virtPackages = with pkgs; [
    qemu
    qemu_kvm
    libvirt
    virt-manager
    bridge-utils
    dnsmasq
    vde2
    ebtables
    iptables
    dmidecode
  ] ++ cfg.extraPackages;

in {
  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf.enable = true;
      };
    };

    programs.virt-manager.enable = true;

    environment.systemPackages = virtPackages;

    # Export virtualization runtime libraries to nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false) (
      virtPackages ++ cfg.nix-ldLibraries
    );
  };
}
