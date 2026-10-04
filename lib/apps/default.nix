# The flake's apps, one file each. Every script is a writeShellApplication, so
# shellcheck runs when it is built and its tools come from runtimeInputs.
{ pkgs, self }:
let
  app = drv: { type = "app"; program = pkgs.lib.getExe drv; };
in {
  os-install    = app (import ./os-install.nix { inherit pkgs self; });
  system-switch = app (import ./system-switch.nix { inherit pkgs; });
  home-switch   = app (import ./home-switch.nix { inherit pkgs; });
  check-purity  = app (import ./check-purity.nix { inherit pkgs; });
}
