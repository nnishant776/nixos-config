{ config, lib, ... }:
let
  cfg = config.conf.sharing;
  enabled = config.conf.networking.enable && cfg.ssh.enable;
in {
  config = lib.mkIf enabled {
    services.openssh = lib.mkMerge [
      ({
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = "no";
          # Only members of ssh-users may log in: privileged users are added
          # automatically (host/privilege.nix); anyone else opts in through
          # `groups`.
          AllowGroups = lib.mkDefault [ "ssh-users" ];
          MaxAuthTries = lib.mkDefault 3;
          LoginGraceTime = lib.mkDefault 30;
          ClientAliveInterval = lib.mkDefault 300;
          ClientAliveCountMax = lib.mkDefault 2;
        };
      })
      (if cfg.ssh.config != {} then cfg.ssh.config else {})
    ];

    # Brute-force protection only matters while passwords are accepted.
    services.sshguard.enable = lib.mkDefault (config.services.openssh.settings.PasswordAuthentication == true);

    warnings = lib.optional
      (config.conf.fleet.repo.url != null && config.services.openssh.settings.PasswordAuthentication == true)
      ("conf.sharing.ssh on '${config.conf.host.name}': password authentication is on for a"
        + " fleet host. Keys through conf.users.accounts.<name>.sshKeys are the intended path.");
  };
}
