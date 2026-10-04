{ lib, ... }: {
  options.conf.host = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        Hostname. Must equal the name of this host's directory under `hosts/`,
        since `nixos-rebuild switch` resolves `#$(hostname)` and home
        configurations are keyed `<user>@<host>`.
      '';
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Kolkata";
      description = "Timezone string.";
    };
    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_IN";
      description = "Default locale; also sets the `LC_*` variables.";
    };
  };
}
