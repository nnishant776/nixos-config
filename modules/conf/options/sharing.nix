{ lib, ... }: {
  options.conf.sharing = {
    enable = lib.mkEnableOption "services that expose this machine to the network";
    ssh = {
      enable = lib.mkEnableOption "the SSH server";
      config = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Merged into `services.openssh`.";
      };
    };
    rdp.enable = lib.mkEnableOption "hosting a remote desktop (GNOME RDP). Connecting to other machines needs nothing here";
  };
}
