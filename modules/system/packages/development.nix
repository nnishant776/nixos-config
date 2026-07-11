{ pkgs, lib, config, ... }: {
  options = {
    system.packages.development.sdk = {
      base = {
        enable = lib.mkEnableOption "Enable installation of basic development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            gh
          ];
        };
      };
      cpp = {
        enable = lib.mkEnableOption  "Enable installation of C/C++ development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            clang
            clang-tools
            cmake
          ];
        };
      };
      go = {
        enable = lib.mkEnableOption  "Enable installation of Go development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            go
          ];
        };
      };
      rust = {
        enable = lib.mkEnableOption  "Enable installation of Rust development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            rustup
          ];
        };
      };
      python = {
        enable = lib.mkEnableOption  "Enable installation of Python development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            python3
          ];
        };
      };
      java = {
        enable = lib.mkEnableOption  "Enable installation of Java development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            zulu
          ];
        };
      };
      nix = {
        enable = lib.mkEnableOption  "Enable installation of Nix development packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            nil
          ];
        };
      };
    };

    system.packages.development.editors = {
      vscode = {
        enable = lib.mkEnableOption "Enable installation of VSCode";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
        };
      };
      neovim = {
        enable = lib.mkEnableOption "Enable installation of Neovim";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            neovim
          ];
        };
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
      emacs = {
        enable = lib.mkEnableOption "Enable installation of Emacs";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            emacs
            libtool # For VTerm
          ];
        };
        config = {
          path = lib.mkOption {
            type = lib.types.str;
            default = "~/.dotfiles/config/emacs";
          };
          repo = lib.mkOption {
            type = lib.types.str;
            default = "https://github.com/janedoe/init.el";
          };
        };
      };
    };
  };

  config = {
    environment.systemPackages = [ ]
      ++ lib.optionals (config.system.packages.development.sdk.base.enable) config.system.packages.development.sdk.base.packages
      ++ lib.optionals (config.system.packages.development.sdk.cpp.enable) config.system.packages.development.sdk.cpp.packages
      ++ lib.optionals (config.system.packages.development.sdk.go.enable) config.system.packages.development.sdk.go.packges
      ++ lib.optionals (config.system.packages.development.sdk.rust.enable) config.system.packages.development.sdk.rust.packages
      ++ lib.optionals (config.system.packages.development.sdk.python.enable) config.system.packages.development.sdk.python.packages
      ++ lib.optionals (config.system.packages.development.sdk.nix.enable) config.system.packages.development.sdk.nix.packages
      ++ lib.optionals (config.system.packages.development.sdk.java.enable) config.system.packages.development.sdk.java.packages
      ++ lib.optionals (config.system.packages.development.editors.vscode.enable) config.system.packages.development.editors.vscode.packages
      ++ lib.optionals (config.system.packages.development.editors.neovim.enable) config.system.packages.development.editors.neovim.packages
      ++ lib.optionals (config.system.packages.development.editors.emacs.enable) config.system.packages.development.editors.emacs.packages;
  };
}
