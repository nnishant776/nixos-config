{ lib, ... }: {
  options.conf.networking = {
    enable = lib.mkEnableOption "networking (NetworkManager)";
    wifi.enable = lib.mkEnableOption "the Wi-Fi backend";
    firewall = {
      enable = lib.mkEnableOption "network firewall configuration";
      config = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Merged into `networking.firewall`.";
      };
    };
  };
}
