# Account password hashes live with the user, not the host: a sops-encrypted
# users/<name>/secrets.yaml with a `password` key, encrypted to every machine
# that declares the account. The hash is applied on every activation, which is
# also how a password is rotated. neededForUsers places the decrypted file
# under /run/secrets-for-users before accounts are created.
{ config, lib, ... }:
let
  usersDir = ../../../users;
  secretFile = name: usersDir + "/${name}/secrets.yaml";
  withSecret = lib.filterAttrs
    (name: _: builtins.pathExists (secretFile name))
    config.conf.users.accounts;
in {
  config = lib.mkIf (withSecret != { }) {
    sops.secrets = lib.mapAttrs' (name: _: lib.nameValuePair "password/${name}" {
      sopsFile = secretFile name;
      key = "password";
      neededForUsers = true;
    }) withSecret;

    users.users = lib.mapAttrs (name: _: {
      hashedPasswordFile = config.sops.secrets."password/${name}".path;
    }) withSecret;
  };
}
