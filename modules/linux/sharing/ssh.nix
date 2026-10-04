{ config, lib, ... }:
let
  cfg = config.conf.sharing;
in {
  config = {
    services.openssh = lib.mkIf (config.conf.networking.enable && cfg.ssh.enable) (lib.mkMerge [
      ({
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = "no";
        };
      })
      (if cfg.ssh.config != {} then cfg.ssh.config else {})
    ]);
  };
}
