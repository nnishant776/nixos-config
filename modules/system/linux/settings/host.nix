{ config, pkgs, lib, ... }: {
  config = {
    # Set hostname
    networking.hostName = config.myconf.host.name;

    # Add registered users
    users.users = lib.listToAttrs (builtins.map (user: lib.nameValuePair user.name {
      isNormalUser = true;
      description = user.fullName;
      extraGroups = lib.unique (
        user.groups
        ++ lib.optionals config.myconf.desktop.enable [ "video" "input" ]
        ++ lib.optionals config.myconf.systemServices.containerisation.enable [ "docker" "podman" ]
        ++ lib.optionals config.myconf.systemServices.virtualisation.enable [ "libvirtd" "kvm" ]
        ++ lib.optionals config.myconf.systemServices.networking.enable [ "networkmanager" ]
      );
      initialHashedPassword = user.initialHashedPassword;
    }) ([ config.myconf.host.adminUser ] ++ config.myconf.host.extraUsers));

    # Set timezone
    time.timeZone = config.myconf.host.timezone;
  };
}
