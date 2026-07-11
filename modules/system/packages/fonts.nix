{ pkgs, lib, config, ... }: {
  options = {
    system.packages.fonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable custom font";
      };
      base = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-color-emoji
          pkgs.liberation_ttf
          pkgs.fira-code
          pkgs.fira-mono
          pkgs.fira-code-symbols
          pkgs.nerd-fonts.liberation
          pkgs.nerd-fonts.noto
          pkgs.nerd-fonts.fira-mono
          pkgs.nerd-fonts.fira-code
        ];
      };
    };
  };

  config = lib.mkIf config.system.packages.fonts.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [] ++ ( config.system.packages.fonts.base );
    };
  };
}
