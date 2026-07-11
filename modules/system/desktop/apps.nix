{ pkgs, lib, config, ... }: {
  options = {
    system.desktop = {
      apps = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [
          pkgs.alacritty
          pkgs.wl-clipboard
          pkgs.brightnessctl
          pkgs.playerctl
          pkgs.pavucontrol
          pkgs.chromium
          pkgs.blueman
        ];
      };
    };
  };

  config = lib.mkIf config.system.desktop.enable {
    environment.systemPackages = with pkgs; [ ]
      ++ config.system.desktop.apps;
  };
}
