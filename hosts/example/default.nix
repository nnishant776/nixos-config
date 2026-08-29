# Reference host exercising every option under `conf/`.
#
# This host is not meant to be deployed — it is a documentation example that
# sets every possible `conf.*` option to a representative value, mirroring the
# full option tree declared in `modules/conf/options.nix`. Use it as a lookup
# when configuring your own machines, and delete/trim as needed.
#
# To instantiate it:
#   nixos-rebuild switch --flake .#reference
#
# NOTE: The values below may pull in heavy packages (KDE-free GNOME-free wayland,
# every SDK, etc.). Keep this host on a throwaway system or don't switch to it.
{ pkgs, lib, ... }:
{
  # ─────────────────────────────────────────────────────────────────────────────
  # conf.profile  — role preset. The presets apply `lib.mkDefault` so explicit
  # values in this file always win. (enum: minimal|server|workstation|developer|gaming|embedded)
  # ─────────────────────────────────────────────────────────────────────────────
  conf.profile = "developer";

  # ─────────────────────────────────────────────────────────────────────────────
  # conf.host — machine identity / locale / users
  # ─────────────────────────────────────────────────────────────────────────────
  conf.host = {
    name = "reference";
    timezone = "Asia/Kolkata";
    locale = "en_IN";

    # conf.host.adminUser — primary admin account (userSubmodule).
    adminUser = {
      name = "admin";
      fullName = "Reference Admin";
      email = "admin@example.com";
      groups = [ "networkmanager" "wheel" "libvirtd" ];
      # `initialHashedPassword` uses mkpasswd format; here we only show a placeholder.
      initialHashedPassword = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
      enableHomeManager = true;
      # conf.host.adminUser.extraHomeConfig — extra home-manager module for this user.
      extraHomeConfig = {
        programs.starship.enable = true;
      };
    };

    # conf.host.extraUsers — additional user accounts (same submodule shape).
    extraUsers = [
      {
        name = "bob";
        fullName = "Bob Example";
        email = "bob@example.com";
        groups = [ "wheel" ];
        enableHomeManager = false;
        extraHomeConfig = {};
      }
    ];

    # conf.host.ldLibraries — exported shared libraries (defaults to ./default-ld-libs.nix).
    ldLibraries = {
      enable = true;
      libraries = with pkgs; [ libGL gtk3 ];
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # conf.desktop — GUI desktop environments & display manager
  # ─────────────────────────────────────────────────────────────────────────────
  conf.desktop = {
    enable = true;

    # environment: (enum: gnome|hyprland|sway|all) — "all" enables every shell.
    environment = "hyprland";

    # conf.desktop.environments.hyprland.shell
    #   (enum: none|caelestia|noctalia) — custom Hyprland shell preset.
    environments.hyprland.shell = "noctalia";

    # conf.desktop.packages — when non-empty, substitutes the built-in default set.
    packages = with pkgs; [ firefox mpv ];
    # conf.desktop.extraPackages — always appended on top of the above.
    extraPackages = with pkgs; [ vlc ];
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # conf.systemServices — infrastructure & services
  # ─────────────────────────────────────────────────────────────────────────────
  conf.systemServices = {
    # conf.systemServices.bootloader
    #   method: (enum: bios|uefi)
    #   program: (enum: systemd-boot|grub|uboot)
    #   allowEFIVariableEdit: bool
    bootloader = {
      method = "uefi";
      program = "systemd-boot";
      allowEFIVariableEdit = true;
    };

    networking = {
      enable = true;
      wifi.enable = true;
    };

    multimedia = {
      enable = true;
      extraPackages = with pkgs; [ ffmpeg mpv ];
      nix-ldLibraries = with pkgs; [ gst_all_1.gstreamer ];
    };

    graphics = {
      enable = true;
      vendor = "intel"; # (enum: intel|amd|nvidia)
      extraPackages = with pkgs; [ mesa ];
      nix-ldLibraries = with pkgs; [ libGL ];
    };

    powerManagement.enable = true;

    containerisation = {
      enable = true;
      extraPackages = with pkgs; [ docker-compose ];
    };

    virtualisation = {
      enable = true;
      extraPackages = with pkgs; [ virt-manager ];
      nix-ldLibraries = with pkgs; [ ];
    };

    # conf.systemServices.homebrew — Darwin/Mac-only; included for completeness.
    homebrew = {
      enable = false;
      brews = [ "wget" "tmux" ];
      casks = [ "firefox" "iterm2" ];
      masApps = { "Xcode" = 497799835; };
      onActivation = {
        autoUpdate = true;
        cleanup = "uninstall"; # (enum: none|uninstall|zap)
        upgrade = true;
      };
    };

    flatpak.enable = true;
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # conf.development — tooling stack
  # ─────────────────────────────────────────────────────────────────────────────
  conf.development = {
    enable = true;
    # conf.development.extraPackages — extra top-level dev packages.
    extraPackages = with pkgs; [ ripgrep fd ];

    # Each SDK group exposes: enable, packages, extraPackages, nix-ldLibraries.
    sdk = {
      base = {
        enable = true;
        packages = with pkgs; [ git gh tmux ];
        extraPackages = with pkgs; [ jq ];
        nix-ldLibraries = with pkgs; [ openssl ];
      };
      cpp = {
        enable = true;
        packages = with pkgs; [ clang-tools cmake ];
        extraPackages = with pkgs; [ boost ];
        nix-ldLibraries = with pkgs; [ ];
      };
      go = {
        enable = true;
        packages = with pkgs; [ go gopls ];
        extraPackages = with pkgs; [ delve ];
        nix-ldLibraries = with pkgs; [ ];
      };
      rust = {
        enable = true;
        packages = with pkgs; [ rustup ];
        extraPackages = with pkgs; [ ];
        nix-ldLibraries = with pkgs; [ ];
      };
      python = {
        enable = true;
        packages = with pkgs; [ python3 ];
        extraPackages = with pkgs; [ uv ];
        nix-ldLibraries = with pkgs; [ ];
      };
      java = {
        enable = true;
        packages = with pkgs; [ zulu17 ];
        extraPackages = with pkgs; [ maven ];
        nix-ldLibraries = with pkgs; [ ];
      };
      nix = {
        enable = true;
        packages = with pkgs; [ nixpkgs-fmt ];
        extraPackages = with pkgs; [ deadnix ];
        nix-ldLibraries = with pkgs; [ ];
      };
      lua = {
        enable = true;
        packages = with pkgs; [ lua ];
        extraPackages = with pkgs; [ lua-language-server ];
        nix-ldLibraries = with pkgs; [ ];
      };
    };

    # Each editor group adds: configPath, configRepo on top of the SDK shape.
    editors = {
      neovim = {
        enable = true;
        configPath = "~/.config/nvim";
        configRepo = "https://github.com/example/nvim";
        packages = with pkgs; [ neovim ];
        extraPackages = with pkgs; [ ripgrep ];
        nix-ldLibraries = with pkgs; [ ];
      };
      emacs = {
        enable = true;
        configPath = "~/.config/emacs";
        configRepo = "https://github.com/example/emacs";
        packages = with pkgs; [ emacs ];
        extraPackages = with pkgs; [ ];
        nix-ldLibraries = with pkgs; [ ];
      };
      vscode = {
        enable = true;
        configPath = "~/.config/Code";
        configRepo = "";
        packages = with pkgs; [ vscode ];
        extraPackages = with pkgs; [ ];
        nix-ldLibraries = with pkgs; [ ];
      };
    };

    # Each tool group exposes: enable, packages, extraPackages, nix-ldLibraries.
    tools = {
      gemini = {
        enable = true;
        packages = with pkgs; [ ];
        extraPackages = with pkgs; [ ];
        nix-ldLibraries = with pkgs; [ ];
      };
      opencode = {
        enable = true;
        packages = with pkgs; [ ];
        extraPackages = with pkgs; [ ];
        nix-ldLibraries = with pkgs; [ ];
      };
      rtk = {
        enable = true;
        packages = with pkgs; [ ];
        extraPackages = with pkgs; [ ];
        nix-ldLibraries = with pkgs; [ ];
      };
    };
  };
}
