# Same wiring as modules/linux/secrets/sops.nix. Password files do not apply:
# Darwin accounts come from MDM.
{ config, lib, ... }:
let
  cfg = config.conf.secrets;
in {
  config = lib.mkIf (cfg.file != null) {
    sops.defaultSopsFile = cfg.file;
    sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
    sops.age.generateKey = lib.mkDefault true;
  };
}
