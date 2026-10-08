# Encrypted disk layout: an unencrypted ESP, then LUKS2 over the rest of the
# disk with LVM inside — a swap volume sized for hibernation and an ext4 root.
# Copy this file to hosts/<name>/disko-config.nix (every .nix file in a host
# directory is imported) and set the swap size. `device` is only a default on
# UEFI: os-install asks which disk to use, or takes it with -d. The swap is
# also what os-install pages to during installation, so 8G or more helps a
# machine with little RAM.
#
# disko asks for the passphrase while formatting (askPassword, the default
# when no password file is given). With conf.hardware.boot.tpm2Unlock the TPM
# can be enrolled as a second unlock method after the first boot — os-install
# prints the command; the passphrase stays as the fallback.
{ config, lib, ... }:
{
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1"; # change to the target disk
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios_boot = lib.mkIf (config.conf.hardware.boot.mode == "bios") {
            type = "EF02";
            size = "1M";
          };
          boot = lib.mkIf (config.conf.hardware.boot.mode == "uefi") {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0077" "dmask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              content = {
                type = "lvm_pv";
                vg = "main";
              };
            };
          };
        };
      };
    };

    lvm_vg.main = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "16G"; # at least the machine's RAM if it should hibernate
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
