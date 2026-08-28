{ ... }:
{
  disko.devices.disk.main = {
    device = "/dev/sda"; # Change to your target disk device (e.g., /dev/nvme0n1)
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        swap = {
          size = "24G"; # Adjust size based on your RAM and hibernation needs
          content = {
            type = "swap";
            discardPolicy = "both"; # Enables TRIM for SSDs if supported
            resumeDevice = true; # Required if you want to use hibernation
          };
        };
        root = {
          size = "100%";
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
