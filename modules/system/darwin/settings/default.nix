{ config, pkgs, lib, flakeLib, ... }:
let
  brewCfg = config.conf.systemServices.homebrew;
  users = config.conf.host.users;

  # null resolves to false here: a Mac's accounts normally come from MDM or
  # from whoever set the laptop up. See conf.host.users.<name>.manageAccount.
  accountManaged = flakeLib.accountManaged config.conf.platform;

  managedUsers = lib.filterAttrs (_: accountManaged) users;
in {
  networking.hostName = config.conf.host.name;
  system.stateVersion = 6;

  # knownUsers is what nix-darwin may create — and may delete: drop a user from
  # conf.host.users and the next activation runs `dscl . -delete` for any uid
  # above 501. nix-darwin's own documentation says not to put the administrator
  # account in it. So only accounts explicitly opted in appear here.
  users.knownUsers = lib.attrNames managedUsers;

  # Every user still gets home and description, because Home-Manager reads the
  # home directory straight off this option — `homeDirectory =
  # config.users.users.${name}.home` in home-manager's nixos/common.nix. Omitting
  # it for unmanaged accounts makes that null and fails the whole evaluation.
  #
  # uid is only set for managed accounts, since nix-darwin requires it for the
  # users it creates and has no default. For the rest the attribute stays
  # undefined, which is inert: nix-darwin only reads uid for users in
  # knownUsers. Reading it directly does throw, which is cosmetic but worth
  # knowing if you go poking at `users.users.<name>.uid` on a Mac host.
  users.users = lib.mapAttrs (username: user:
    {
      home = "/Users/${username}";
      description = user.fullName;
    }
    // lib.optionalAttrs (accountManaged user && user.uid != null) { uid = user.uid; }
    # nix-darwin defaults gid to 20 (staff), which is what a normal macOS
    # account uses, so it is only set when asked for.
    // lib.optionalAttrs (accountManaged user && user.gid != null) { gid = user.gid; }
  ) users;

  assertions = lib.mapAttrsToList (username: user: {
    assertion = user.uid != null;
    message =
      "conf.host.users.${username} on '${config.conf.host.name}' has"
      + " manageAccount = true, which puts it in users.knownUsers so nix-darwin"
      + " creates and maintains it — but uid is unset and nix-darwin has no"
      + " default. It must match the id the account already has, or activation"
      + " warns about an unexpected uid and skips the user.";
  }) managedUsers;

  homebrew = lib.mkIf brewCfg.enable {
    enable = true;
    brews = brewCfg.brews;
    casks = brewCfg.casks;
    masApps = brewCfg.masApps;
    onActivation = brewCfg.onActivation;
  };
}
