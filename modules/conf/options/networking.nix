{ lib, ... }: {
  options.conf.networking = {
    enable = lib.mkEnableOption "networking (NetworkManager)";
    wifi.enable = lib.mkEnableOption "the Wi-Fi backend";
    firewall = {
      enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = ''
          `null` leaves the NixOS firewall at its default, which is on. `true`
          or `false` sets it explicitly; `false` is rejected on a fleet host.
          Ports are opened by the service that owns them, never listed here.
        '';
      };
      config = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Merged into `networking.firewall`.";
      };
    };
  };
}
