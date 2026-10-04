{ lib, config, ... }:
{
  config = lib.mkIf config.conf.desktop.enable {
    services.pipewire = {
        enable = true;                      # Piperwire multimedia service
        alsa.enable = true;                 # Alsa audio plugin
        pulse.enable = true;                # PulseAudio plugin
        wireplumber = {
          enable = true;                    # Pipewire session and policy manager
        };
      };
  };
}
