{ config, pkgs, lib, ... }:
let
  ldCfg = config.conf.host.ldLibraries;

  # Kept here rather than as the option default so that the list, which holds
  # Linux-only packages, is never forced on Darwin.
  defaultLdLibraries = import ../../conf/default-ld-libs.nix { inherit pkgs; };

  ldLibraries =
    (if ldCfg.libraries != [ ] then ldCfg.libraries else defaultLdLibraries)
    ++ ldCfg.extraLibraries;
in {
  config = {
    environment.sessionVariables = {
      PATH = [ "/usr/local/bin" "/usr/bin" "/opt/bin" ];
    };

    programs.nix-index.enable = true;

    # Enable nix-ld for precompiled dynamic binary execution
    programs.nix-ld = {
      enable = true;
      libraries = lib.mkIf ldCfg.enable ldLibraries;
    };

    environment.systemPackages = with pkgs; [
      # Hardware utilitites
      usbutils
      pciutils
      dmidecode
      biosdevname
    ];
  };
}
