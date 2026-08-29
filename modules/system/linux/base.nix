{ config, pkgs, lib, ... }: {
  config = {
    environment.sessionVariables = {
      PATH = [ "/usr/local/bin" "/usr/bin" "/opt/bin" ];
    };

    programs.nix-index.enable = true;

    # Enable nix-ld for precompiled dynamic binary execution
    programs.nix-ld = {
      enable = true;
      libraries = lib.mkIf config.conf.host.ldLibraries.enable config.conf.host.ldLibraries.libraries;
    };
  };
}
