{ config, lib, ... }:
let
  cfg = config.myconf;
  mk = lib.mkDefault;
in {
  config = lib.mkMerge [
    # ── Desktop implications ──
    (lib.mkIf cfg.desktop.enable {
      myconf.systemServices.multimedia.enable      = mk true;
      myconf.systemServices.graphics.enable        = mk true;
      myconf.systemServices.powerManagement.enable = mk true;
      myconf.systemServices.flatpak.enable         = mk true;
    })
  ];
}
