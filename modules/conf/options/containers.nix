{ lib, ... }: {
  options.conf.containers = {
    enable = lib.mkEnableOption "the Docker and Podman container engines";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra container tooling.";
    };
  };
}
