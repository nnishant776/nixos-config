# What the machine physically is, orthogonal to conf.role. The defaults each
# type contributes (wireless and power on a laptop, guest agents in a VM, the
# headless posture on a server) arrive with the hardening work; in this pass
# the option exists and defaults from the role, and contributes nothing, so
# that behaviour is unchanged.
{ config, lib, ... }:
let
  headlessRoles = [ "server" "minimal" "embedded" ];
in {
  options.conf.machineType = lib.mkOption {
    type = lib.types.enum [ "laptop" "desktop" "headless" "vm" ];
    default = if builtins.elem config.conf.role headlessRoles then "headless" else "desktop";
    defaultText = lib.literalMD ''`"headless"` for the server, minimal and embedded roles, otherwise `"desktop"`'';
    description = ''
      Form factor of this machine. `laptop` and `desktop` are interactive
      machines; `headless` is a server or appliance with no display; `vm` is a
      guest. Deduced from `conf.role` and overridable.
    '';
  };
}
