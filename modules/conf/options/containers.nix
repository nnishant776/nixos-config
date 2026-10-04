{ lib, ... }: {
  options.conf.containers = {
    enable = lib.mkEnableOption "the Docker and Podman container engines";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra container tooling.";
    };
    registries = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "docker.io" "quay.io" "ghcr.io" "registry.k8s.io" ];
      description = ''
        Registries images may be pulled from. Podman, skopeo and buildah reject
        any other source through `policy.json`; the list is also the
        unqualified-name search order. Docker has no equivalent control.
      '';
    };
  };
}
