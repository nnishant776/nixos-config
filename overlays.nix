{ inputs, config, lib, pkgs, ... }:
{
  nixpkgs.overlays = lib.mkIf (config.conf.desktop.environment != "gnome") [
    (final: prev: {
      xdg-desktop-portal-gtk = prev.xdg-desktop-portal-gtk.overrideAttrs (prevAttrs: {
        buildInputs = builtins.filter (x:
          x != prev.gnome-desktop
          && x != prev.gnome-settings-daemon
        ) prevAttrs.buildInputs;
        mesonFlags = [
          "-Dwallpaper=disabled"
          "-Dsettings=disabled"
          "-Dappchooser=disabled"
          "-Dlockdown=disabled"
        ];
      });
    })
  ];
}
