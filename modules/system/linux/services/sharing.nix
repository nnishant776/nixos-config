{ config, pkgs, lib, ... }:
let
  svcCfg = config.conf.systemServices;
  cfg = svcCfg.sharing;
in {
  config = {
    services.openssh = lib.mkIf (svcCfg.networking.enable && svcCfg.sharing.ssh.enable) (lib.mkMerge [
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
