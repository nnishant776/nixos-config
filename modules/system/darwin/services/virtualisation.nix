{ config, lib, pkgs, ... }:
let
  cfg = config.conf.systemServices.virtualisation;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      colima
      lima
      lima-additional-guestagents
    ] ++ cfg.extraPackages;

    system.activationScripts.enableRosetta2.txt = ''
      echo "Enabling Rosetta 2"
      softwareupdate --install-rosetta --agree-to-license || true
    '';
  };
}
