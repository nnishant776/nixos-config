{ config, pkgs,lib, ... }:
let
  cfg = config.conf.systemServices.networking;
in {
  config  = lib.mkIf cfg.enable {
    # Force bluez installation
    environment.systemPackages = with pkgs; [
      bluez
    ];

    # Enable bluetooth adapter
    hardware = lib.mkIf cfg.bluetooth.enable {
      enableAllFirmware = true;
      bluetooth = {
        enable = true;
      };
      alsa = {
        enableBluetooth = true;
      };
    };

    # Enabe bluetooth management service
    services = lib.mkIf cfg.bluetooth.enable {
      blueman.enable = true;
    };
  };
}
