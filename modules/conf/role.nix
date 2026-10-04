# What the machine is for. Each role is a set of conf.* defaults, applied with
# flakeLib.mkDefaults so that a host's own values always win. Roles inherit
# with lib.recursiveUpdate rather than `//`, which would replace a whole
# top-level attribute and silently drop inherited leaves beneath it.
{ config, lib, flakeLib, ... }:
let
  extend = lib.recursiveUpdate;

  roles = rec {
    minimal = {
      networking.enable = true;
    };

    server = extend minimal {
      containers.enable = true;
      virtualisation.enable = true;
      development = {
        enable = true;
        sdk.base.enable = true;
      };
    };

    # Wi-Fi, Bluetooth and power management are machineType concerns (laptop,
    # desktop), not role ones.
    workstation = extend minimal {
      hardware.graphics.enable = true;
      desktop = {
        enable = true;
        multimedia.enable = true;
      };
      flatpak.enable = true;
    };

    developer = extend workstation {
      containers.enable = true;
      virtualisation.enable = true;
      development = {
        enable = true;
        sdk = {
          base.enable = true;
          cpp.enable = true;
          go.enable = false;
          rust.enable = false;
          python.enable = false;
          java.enable = false;
          nix.enable = false;
          lua.enable = false;
        };
        editors = {
          neovim.enable = true;
          emacs.enable = false;
        };
      };
    };

    gaming = workstation;

    embedded = extend minimal {
      development = {
        enable = true;
        sdk = {
          base.enable = true;
          cpp.enable = true;
        };
      };
    };
  };
in {
  options.conf.role = lib.mkOption {
    type = lib.types.enum (builtins.attrNames roles);
    default = "minimal";
    description = ''
      What this machine is for. Sets defaults across the `conf.*` tree; the
      host overrides any of them with a plain value. Hardware and form-factor
      concerns are `conf.machineType`, not the role.
    '';
  };

  # One mkIf per role, each with a static set of attribute names, so the
  # module system never has to evaluate conf.role to learn which options are
  # being defined.
  config = lib.mkMerge (lib.mapAttrsToList
    (name: defs: lib.mkIf (config.conf.role == name) { conf = flakeLib.mkDefaults defs; })
    roles);
}
