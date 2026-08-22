{ config, lib, ... }:
let
  cfg = config.myconf;
  mk = lib.mkDefault;
in {
  config = lib.mkMerge [
    # ── minimal ──
    (lib.mkIf (cfg.profile == "minimal") {
      myconf.systemServices.networking.enable = mk true;
    })

    # ── server ──
    (lib.mkIf (cfg.profile == "server") {
      myconf.systemServices.networking.enable       = mk true;
      myconf.systemServices.containerisation.enable = mk true;
      myconf.systemServices.virtualisation.enable   = mk true;
      myconf.development.enable                     = mk true;
      myconf.development.sdk.base.enable            = mk true;
    })

    # ── workstation ──
    (lib.mkIf (cfg.profile == "workstation") {
      myconf.systemServices.networking.enable      = mk true;
      myconf.systemServices.networking.wifi.enable = mk true;
      myconf.systemServices.audio.enable           = mk true;
      myconf.systemServices.graphics.enable        = mk true;
      myconf.desktop.enable                        = mk true;
      myconf.systemServices.powerManagement.enable = mk true;
      myconf.systemServices.flatpak.enable         = mk true;
    })

    # ── developer (extends workstation) ──
    (lib.mkIf (cfg.profile == "developer") {
      myconf.systemServices.networking.enable       = mk true;
      myconf.systemServices.networking.wifi.enable  = mk true;
      myconf.systemServices.audio.enable            = mk true;
      myconf.systemServices.graphics.enable         = mk true;
      myconf.desktop.enable                         = mk true;
      myconf.systemServices.powerManagement.enable  = mk true;
      myconf.systemServices.flatpak.enable          = mk true;
      myconf.systemServices.containerisation.enable = mk true;
      myconf.systemServices.virtualisation.enable   = mk true;

      myconf.development.enable                     = mk true;
      myconf.development.sdk.base.enable            = mk true;
      myconf.development.sdk.cpp.enable             = mk true;
      myconf.development.sdk.go.enable              = mk true;
      myconf.development.sdk.rust.enable            = mk true;
      myconf.development.sdk.python.enable          = mk true;
      myconf.development.sdk.java.enable            = mk true;
      myconf.development.sdk.nix.enable             = mk true;
      myconf.development.sdk.lua.enable             = mk true;

      myconf.development.editors.neovim.enable      = mk true;
      myconf.development.editors.emacs.enable       = mk true;
    })

    # ── gaming (extends workstation) ──
    (lib.mkIf (cfg.profile == "gaming") {
      myconf.systemServices.networking.enable      = mk true;
      myconf.systemServices.networking.wifi.enable = mk true;
      myconf.systemServices.audio.enable           = mk true;
      myconf.systemServices.graphics.enable        = mk true;
      myconf.desktop.enable                        = mk true;
      myconf.systemServices.powerManagement.enable = mk true;
      myconf.systemServices.flatpak.enable         = mk true;
    })

    # ── embedded ──
    (lib.mkIf (cfg.profile == "embedded") {
      myconf.systemServices.networking.enable = mk true;
      myconf.development.enable               = mk true;
      myconf.development.sdk.base.enable      = mk true;
      myconf.development.sdk.cpp.enable       = mk true;
    })
  ];
}
