{ lib, ... }:
{
  config = {
    services.journald.extraConfig = lib.mkDefault ''
      SystemMaxUse=1G
      MaxRetentionSec=90day
    '';
    # Log shipping is deferred until the organisation has a collector. When it
    # does, this is where it goes, with the client certificate from
    # conf.secrets:
    #   services.journald.upload = {
    #     enable = true;
    #     settings.Upload.URL = "https://collector.example:19532";
    #   };
  };
}
