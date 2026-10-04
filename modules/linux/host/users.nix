{ config, lib, ... }:
{
  config = {
    users.users = lib.mapAttrs (username: user: {
      isNormalUser = true;
      description = user.fullName;
      initialHashedPassword = user.initialHashedPassword;
    }) config.conf.users.accounts;
  };
}
