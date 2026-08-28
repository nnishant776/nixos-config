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

    # Set up first boot tasks
    systemd.services.run-once-on-first-boot = {
      description = "Run script exactly once on first boot";

      # Ensure it runs late enough if you need networking or full system initialized
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];

      # This condition prevents the service from running if the file already exists
      unitConfig = {
        ConditionPathExists = "!/var/lib/run-once-on-first-boot.done";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        echo "Executing first-boot initialization tasks..."

        # Commands to run on first boot
        touch /root/.disko-partitioning.done

        # Create the token file so this service is skipped on subsequent boots
        touch /var/lib/run-once-on-first-boot.done
      '';
    };
  };
}
