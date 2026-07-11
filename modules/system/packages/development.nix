{ pkgs, lib, config, ... }: {
  options = {
    system.packages.development.sdk = {
      base = {
        enable = lib.mkEnableOption "Enable installation of basic development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.gh
          ];
        };
      };
      cpp = {
        enable = lib.mkEnableOption  "Enable installation of C/C++ development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.clang
            pkgs.clang-tools
          ];
        };
      };
      go = {
        enable = lib.mkEnableOption  "Enable installation of Go development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.go
          ];
        };
      };
      rust = {
        enable = lib.mkEnableOption  "Enable installation of Rust development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.rustup
          ];
        };
      };
      python = {
        enable = lib.mkEnableOption  "Enable installation of Python development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.python3
          ];
        };
      };
      java = {
        enable = lib.mkEnableOption  "Enable installation of Java development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [
            pkgs.zulu
          ];
        };
      };
    };

    system.packages.development.editors = {
      vscode = {
        enable = lib.mkEnableOption "Enable installation of VSCode";
      };
      neovim = {
        enable = lib.mkEnableOption "Enable installation of Neovim (No configuration)";
        config = {
          path = lib.mkOption {
            type = lib.types.str;
            default = "~/.dotfiles/config/nvim";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            default = "https://github.com/janedoe/init.lua";
          };
        };
      };
    };
  };

  config = {
    environment.systemPackages = [ ]
      ++ lib.optionals (config.system.packages.development.sdk.base.enable) config.system.packages.development.sdk.base.packages
      ++ lib.optionals (config.system.packages.development.sdk.cpp.enable) config.system.packages.development.sdk.cpp.packges
      ++ lib.optionals (config.system.packages.development.sdk.go.enable) config.system.packages.development.sdk.go.packges
      ++ lib.optionals (config.system.packages.development.sdk.rust.enable) config.system.packages.development.sdk.rust.packges
      ++ lib.optionals (config.system.packages.development.sdk.python.enable) config.system.packages.development.sdk.python.packges
      ++ lib.optionals (config.system.packages.development.sdk.java.enable) config.system.packages.development.sdk.java.packges
      ++ lib.optionals (config.system.packages.development.editors.vscode) [
        pkgs.vscode
      ] ++ lib.optionals (config.system.packages.development.editors.vscode) [
        pkgs.neovim
        # pkgs.lunarvim
      ];
  };
}
