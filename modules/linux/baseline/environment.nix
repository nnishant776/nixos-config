{ pkgs, ... }:
{
  config = {
    environment.sessionVariables = {
      PATH = [ "/usr/local/bin" "/usr/bin" "/opt/bin" ];
    };

    programs.nix-index.enable = true;

    environment.systemPackages = with pkgs; [
      # Hardware utilitites
      usbutils
      pciutils
      dmidecode
      biosdevname
    ];
  };
}
