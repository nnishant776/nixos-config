{ config, pkgs, lib, flakeLib, ... }:
let
  brewCfg = config.conf.systemServices.homebrew;
  users = config.conf.host.users;

  # null resolves to false here: a Mac's accounts normally come from MDM.
  # See conf.host.users.<name>.manageAccount.
  accountManaged = flakeLib.accountManaged config.conf.platform;

  managedUsers = lib.filterAttrs (_: accountManaged) users;
in {
  networking.hostName = config.conf.host.name;
  system.stateVersion = 6;

  # knownUsers is also nix-darwin's delete list: drop a user from
  # conf.host.users and the next activation runs `dscl . -delete` for them.
  # Only accounts explicitly opted in appear here.
  users.knownUsers = lib.attrNames managedUsers;

  # Every user needs home set regardless of management, since Home Manager
  # reads it unconditionally. uid is required for managed accounts (no
  # default for the users nix-darwin creates) and otherwise left unset.
  users.users = lib.mapAttrs (username: user:
    {
      home = "/Users/${username}";
      description = user.fullName;
    }
    // lib.optionalAttrs (accountManaged user && user.uid != null) { uid = user.uid; }
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
