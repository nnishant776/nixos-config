# Hosting a remote desktop is a sharing decision, not a side effect of GNOME,
# which would otherwise enable gnome-remote-desktop on its own. This file owns
# that option; desktop/shells/gnome.nix does not touch it.
{ config, lib, ... }:
let
  cfg = config.conf.sharing;
in {
  config = {
    services.gnome.gnome-remote-desktop.enable = cfg.enable && cfg.rdp.enable;
  };
}
