{ config, lib, ... }:
let
  hwdCfg = config.conf.hardware;

  earlyKms = {
    intel = [ "i915" ];
    amd = [ "amdgpu" ];
  };
in {
  config = lib.mkMerge [
    {
      boot.loader.${hwdCfg.boot.loader}.enable = true;
      boot.loader.efi.canTouchEfiVariables = hwdCfg.boot.efiVariables;
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

    (lib.mkIf (hwdCfg.boot.mode == "bios") {
      conf.hardware.boot.loader = lib.mkDefault "grub";
    })
    (lib.mkIf (hwdCfg.boot.splash.enable) {
      boot = {
        plymouth = {
          enable = true;
          theme = hwdCfg.boot.splash.theme;
          themePackages = hwdCfg.boot.splash.themePackages;
        };

        # Nothing but the splash on screen: kernel messages below "error",
        # udev and systemd status lines off (failures are still in the
        # journal), and no initrd chatter. systemd stage 1, on for every host,
        # is what lets Plymouth show the LUKS passphrase prompt on an
        # encrypted disk.
        consoleLogLevel = 3;
        kernelParams = [
          "quiet"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
          "rd.systemd.show_status=false"
          "systemd.show_status=false"
        ];
        initrd.verbose = false;

        # The generation menu is hidden; it is still one key away. On
        # systemd-boot, press Space (or any key) repeatedly as the machine
        # starts. On GRUB, hold Shift or press Esc during the second it waits.
        # A host that wants the menu back sets boot.loader.timeout.
        loader.timeout = lib.mkDefault (if hwdCfg.boot.loader == "grub" then 1 else 0);
        loader.grub.timeoutStyle = lib.mkDefault "hidden";
      };
    })

    # Plymouth starts in the initrd, on the firmware's framebuffer with the
    # vendor logo. If the GPU driver only loads in stage 2, it takes the screen
    # over mid-boot: the logo is wiped and the console shows through. Loading
    # it in the initrd (early KMS) gives Plymouth the final display from the
    # start, and on recent Intel GPUs the driver keeps the firmware's mode, so
    # the logo never flickers. The same applies with or without disk
    # encryption. NVIDIA's proprietary driver is left out: in the initrd it is
    # large and fragile, and the firmware framebuffer serves well enough.
    (lib.mkIf (hwdCfg.boot.splash.enable && hwdCfg.graphics.enable) {
      boot.initrd.kernelModules = earlyKms.${hwdCfg.graphics.vendor} or [ ];
    })
  ];
}
