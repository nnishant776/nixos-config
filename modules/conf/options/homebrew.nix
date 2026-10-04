{ lib, ... }: {
  options.conf.homebrew = {
    enable = lib.mkEnableOption "Homebrew (Darwin only)";
    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Formulae to install.";
    };
    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Casks to install.";
    };
    masApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = { };
      description = "Mac App Store applications to install, as `Name = AppID`.";
    };
    onActivation = {
      autoUpdate = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Update Homebrew itself on activation.";
      };
      cleanup = lib.mkOption {
        type = lib.types.enum [ "none" "uninstall" "zap" ];
        default = "none";
        description = "What to do with formulae and casks not listed here.";
      };
      upgrade = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Upgrade installed packages on activation.";
      };
    };
  };
}
