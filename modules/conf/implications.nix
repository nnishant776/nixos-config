{ config, lib, ... }:
let
  cfg = config.conf;
  mk = lib.mkDefault;
in {
  config = lib.mkMerge [
    # ── Desktop implications ──
    (lib.mkIf cfg.desktop.enable {
      conf.systemServices.multimedia.enable      = mk true;
      conf.systemServices.graphics.enable        = mk true;
      conf.systemServices.powerManagement.enable = mk true;
      conf.systemServices.flatpak.enable         = mk true;
    })
  ];
}
