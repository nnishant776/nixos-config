{ pkgs, lib, config, ... }: {
  options = {
    system.desktop = {
      apps = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          alacritty
          wl-clipboard
          brightnessctl
          playerctl
          pavucontrol
          chromium
          blueman
        ];
      };
    };
  };

  config = lib.mkIf config.system.desktop.enable {
    environment.systemPackages = with pkgs; [ ]
      ++ config.system.desktop.apps;
  };
}
