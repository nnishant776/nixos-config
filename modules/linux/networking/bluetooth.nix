{ config, pkgs,lib, ... }:
let
  cfg = config.conf.networking;
in {
  config  = lib.mkIf cfg.enable {
    # Force bluez installation
    environment.systemPackages = with pkgs; [
      bluez
    ];

    # Enable bluetooth adapter
    hardware = lib.mkIf config.conf.hardware.bluetooth.enable {
      enableAllFirmware = true;
      bluetooth = {
        enable = true;
      };
      alsa = {
        enableBluetooth = true;
      };
    };

    # Enabe bluetooth management service
    services = lib.mkIf config.conf.hardware.bluetooth.enable {
      blueman.enable = true;
    };
  };
}
