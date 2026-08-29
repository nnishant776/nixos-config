{ config, lib, ... }:
let
  cfg = config.conf;
  mk = lib.mkDefault;
in {
  config = lib.mkMerge [
    # ── minimal ──
    (lib.mkIf (cfg.profile == "minimal") {
      conf.systemServices.networking.enable = mk true;
    })

    # ── server ──
    (lib.mkIf (cfg.profile == "server") {
      conf.systemServices.networking.enable       = mk true;
      conf.systemServices.containerisation.enable = mk true;
      conf.systemServices.virtualisation.enable   = mk true;
      conf.development.enable                     = mk true;
      conf.development.sdk.base.enable            = mk true;
    })

    # ── workstation ──
    (lib.mkIf (cfg.profile == "workstation") {
      conf.systemServices.networking.enable      = mk true;
      conf.systemServices.networking.wifi.enable = mk true;
      conf.systemServices.multimedia.enable      = mk true;
      conf.systemServices.graphics.enable        = mk true;
      conf.desktop.enable                        = mk true;
      conf.systemServices.powerManagement.enable = mk true;
      conf.systemServices.flatpak.enable         = mk true;
    })

    # ── developer (extends workstation) ──
    (lib.mkIf (cfg.profile == "developer") {
      conf.systemServices.networking.enable       = mk true;
      conf.systemServices.networking.wifi.enable  = mk true;
      conf.systemServices.multimedia.enable       = mk true;
      conf.systemServices.graphics.enable         = mk true;
      conf.desktop.enable                         = mk true;
      conf.systemServices.powerManagement.enable  = mk true;
      conf.systemServices.flatpak.enable          = mk true;
      conf.systemServices.containerisation.enable = mk true;
      conf.systemServices.virtualisation.enable   = mk true;

      conf.development.enable                     = mk true;
      conf.development.sdk.base.enable            = mk true;
      conf.development.sdk.cpp.enable             = mk true;
      conf.development.sdk.go.enable              = mk true;
      conf.development.sdk.rust.enable            = mk true;
      conf.development.sdk.python.enable          = mk true;
      conf.development.sdk.java.enable            = mk true;
      conf.development.sdk.nix.enable             = mk true;
      conf.development.sdk.lua.enable             = mk true;

      conf.development.editors.neovim.enable      = mk true;
      conf.development.editors.emacs.enable       = mk true;
    })

    # ── gaming (extends workstation) ──
    (lib.mkIf (cfg.profile == "gaming") {
      conf.systemServices.networking.enable      = mk true;
      conf.systemServices.networking.wifi.enable = mk true;
      conf.systemServices.multimedia.enable      = mk true;
      conf.systemServices.graphics.enable        = mk true;
      conf.desktop.enable                        = mk true;
      conf.systemServices.powerManagement.enable = mk true;
      conf.systemServices.flatpak.enable         = mk true;
    })

    # ── embedded ──
    (lib.mkIf (cfg.profile == "embedded") {
      conf.systemServices.networking.enable = mk true;
      conf.development.enable               = mk true;
      conf.development.sdk.base.enable      = mk true;
      conf.development.sdk.cpp.enable       = mk true;
    })
  ];
}
