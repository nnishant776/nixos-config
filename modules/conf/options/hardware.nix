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

    powerManagement.enable = lib.mkEnableOption "the power management daemons (tuned, upower)";

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
      grubPasswordHash = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "grub.pbkdf2.sha512.10000.674DFF...";
        description = ''
          GRUB superuser password hash, from `grub-mkpasswd-pbkdf2`. GRUB has no
          switch to turn off its menu editor, which lets anyone at the keyboard
          change the kernel command line (`init=/bin/sh`); a superuser does.
          The current system still boots without a password; editing an entry,
          the GRUB console and older generations ask for it. Only used when
          the loader is GRUB; the hash is stored in the open, which is what
          PBKDF2 hashes are for. It cannot come from `conf.secrets`, since the
          bootloader is installed before secrets are decrypted.
        '';
      };
      splash = {
        enable = lib.mkEnableOption "the boot splash (Plymouth)";
        theme = lib.mkOption {
          type = lib.types.str;
          default = "bgrt";
          description = "Plymouth theme. `bgrt` shows the firmware vendor logo.";
        };
        themePackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = ''
            Packages providing `theme`. The themes bundled with Plymouth (bgrt,
            spinner, tribar, fade-in, glow, solar, spinfinity, script, details,
            text) need none.
          '';
        };
      };
    };
  };
}
