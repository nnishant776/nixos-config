{ config, pkgs, lib, ... }: {
  options = {
    system.settings.host = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        default = "Asia/Kolkata";
      };
      adminUser = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "admin";
        };
        fullName = lib.mkOption {
          type = lib.types.str;
          default = "Administrator";
        };
        groups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "admin" ];
        };
        initialHashedPassword = lib.mkOption {
          type = lib.types.str;
          # WARNING: Make sure to change this after installation
          default = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
        };
      };
      extraUsers = lib.mkOption {
        default = [];
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "jdoe";
            };
            fullName = lib.mkOption {
              type = lib.types.str;
              default = "Jane Doe";
            };
            groups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "jdoe" ];
            };
            initialHashedPassword = lib.mkOption {
              type = lib.types.str;
              # WARNING: Make sure to change this after installation
              default = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
            };
          };
        });
      };
    };
  };

  config = {
    # Change network settings
    networking.hostName = config.system.settings.host.name;
    networking.networkmanager.enable = true;

    # Add users
    users.users = lib.listToAttrs (builtins.map (user: lib.nameValuePair user.name {
      isNormalUser = true;
      description = user.fullName;
      extraGroups = user.groups;
      initialHashedPassword = user.initialHashedPassword;
    }) ( 
      [ config.system.settings.host.adminUser ] ++
      config.system.settings.host.extraUsers
    ));

    # Set timezone
    time.timeZone = config.system.settings.host.timezone;
  };
}
