{ inputs, pkgs, lib, config, ... }: {
  options = {
    system.packages.fonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable custom font";
      };
      base = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          liberation_ttf
          fira-code
          fira-mono
          fira-code-symbols
          nerd-fonts.liberation
          nerd-fonts.symbols-only
          nerd-fonts.noto
          nerd-fonts.fira-mono
          nerd-fonts.fira-code
          inputs.apple-fonts.packages.${pkgs.system}.sf-pro
          inputs.apple-fonts.packages.${pkgs.system}.sf-mono
        ];
      };
    };
  };

  config = lib.mkIf config.system.packages.fonts.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = ( config.system.packages.fonts.base );
    };
  };
}
