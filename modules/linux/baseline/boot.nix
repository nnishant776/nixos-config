{ config, lib, ... }:
{
  config = lib.mkMerge [
    {
      boot.loader.${config.conf.hardware.boot.loader}.enable = true;
      boot.loader.efi.canTouchEfiVariables = config.conf.hardware.boot.efiVariables;
    }

    # A separate set: Nix does not allow the dynamic `${loader}` path above and a
    # static `systemd-boot` path in one literal.
    {
      # No editing the kernel command line from the boot menu (init=/bin/sh is
      # a root shell), and a bounded menu so /boot does not fill and old
      # generations do not stay bootable forever.
      boot.loader.systemd-boot.editor = lib.mkDefault false;
      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
      boot.loader.grub.configurationLimit = lib.mkDefault 10;
    }

    (lib.mkIf (config.conf.hardware.boot.mode == "bios") {
      conf.hardware.boot.loader = lib.mkDefault "grub";
    })
  ];
}
