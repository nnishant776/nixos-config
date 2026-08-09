{ pkgs, lib, config, ... }: {
  options = {
    system.packages.containerisation = {
      enable = lib.mkEnableOption "Enable installation of containerization packages";
    };
  };

  config = {
    # Install and enable docker
    virtualisation = {
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
    };

    # Install and enable podman
    virtualisation = {
      containers = {
        enable = true;
      };
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # Install docker tools
    environment.systemPackages = with pkgs; [
      docker-buildx
      docker-compose
      podman-compose
    ];
  };
}
