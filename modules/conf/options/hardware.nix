{ lib, ... }: {
  options.conf.hardware = {
    graphics = {
      enable = lib.mkEnableOption "hardware graphics acceleration";
      vendor = lib.mkOption {
        type = lib.types.enum [ "intel" "amd" "nvidia" ];
        default = "intel";
        description = "GPU vendor, which selects the driver packages.";
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Extra graphics packages.";
      };
      nix-ldLibraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Runtime shared libraries exported to nix-ld for graphics.";
      };
    };

    bluetooth.enable = lib.mkEnableOption "the Bluetooth stack";

    power.enable = lib.mkEnableOption "the power management daemons (tuned, upower)";

    boot = {
      mode = lib.mkOption {
        type = lib.types.enum [ "bios" "uefi" ];
        default = "uefi";
        description = "Firmware interface the machine boots with.";
      };
      loader = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "systemd-boot" "grub" "uboot" ]);
        default = "systemd-boot";
        description = "Bootloader to install. Defaults to GRUB when `mode` is `bios`.";
      };
      efiVariables = lib.mkEnableOption "letting the bootloader write EFI variables";
      tpm2Unlock = lib.mkEnableOption "unlocking LUKS volumes with the TPM at boot (systemd-cryptenroll; the passphrase remains as fallback)";
    };
  };
}
