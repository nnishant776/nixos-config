# sops-nix wiring. Each machine holds its own age key, generated on first
# activation; the public half goes into .sops.yaml so secrets can be encrypted
# to it. Nothing here is active until the host names a secrets file.
{ config, lib, ... }:
let
  cfg = config.conf.secrets;
in {
  # Active for a host file or for any secret declared elsewhere, such as the
  # per-user password files in secrets/users.nix.
  config = lib.mkIf (cfg.file != null || config.sops.secrets != { }) {
    sops.defaultSopsFile = lib.mkIf (cfg.file != null) cfg.file;
    sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
    sops.age.generateKey = lib.mkDefault true;
  };
}
