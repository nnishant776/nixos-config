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
  nixpkgs.hostPlatform = "x86_64-linux";
  fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; };

  # ───────────────────────────────────────────────────────────────────────────
  # conf.profile  — role preset. The presets apply `lib.mkDefault` so explicit
  # values in this file always win. (enum: minimal|server|workstation|developer|gaming|embedded)
  # ───────────────────────────────────────────────────────────────────────────
  conf.profile = "developer";

  # ───────────────────────────────────────────────────────────────────────────
  # conf.host — machine identity / locale / users
  # ───────────────────────────────────────────────────────────────────────────
  conf.host = {
    name = "reference";
    timezone = "Asia/Kolkata";
    locale = "en_IN";

    # conf.host.adminUser — primary admin account (userSubmodule).
    adminUser = {
      name = "admin";
      fullName = "Reference Admin";
      email = "admin@example.com";
      groups = [ "networkmanager" "wheel" ];
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

  # ───────────────────────────────────────────────────────────────────────────
  # conf.desktop — GUI desktop environments & display manager
  # ───────────────────────────────────────────────────────────────────────────
  conf.desktop = {
    enable = true;

    # environment: (enum: gnome|hyprland|sway|all) — "all" enables every shell.
    environment = "hyprland";

    # Per-environment options (when that environment is active).
    environments = {
      hyprland = {
        # shell: (enum: none|caelestia|noctalia|dms)
        shell = "dms";
      };
    };
  };

  # ───────────────────────────────────────────────────────────────────────────
  # conf.development — SDKs, editors, and CLI tools
  # ───────────────────────────────────────────────────────────────────────────
  conf.development = {
    enable = true;

    # SDK language toolchains.
    sdk = {
      base.enable = true; # core tools: gcc, gnumake, git, curl, jq, etc.
      cpp = {
        enable = true;
        extraPackages = with pkgs; [ clang-tools valgrind ];
        nix-ldLibraries = with pkgs; [ boost ];
      };
      nix = {
        enable = true;
        extraPackages = with pkgs; [ nil nixpkgs-fmt ];
      };
      lua = {
        enable = true;
        extraPackages = with pkgs; [ lua-language-server stylua ];
      };
      go = {
        enable = true;
        extraPackages = with pkgs; [ gopls golangci-lint ];
      };
      rust = {
        enable = true;
        extraPackages = with pkgs; [ rust-analyzer clippy ];
      };
      python = {
        enable = true;
        extraPackages = with pkgs; [ pyright black ];
        nix-ldLibraries = with pkgs; [ zlib ];
      };
      java = {
        enable = true;
        extraPackages = with pkgs; [ jdt-language-server ];
      };
      cue = {
        enable = true;
      };
    };

    # Editor configurations.
    editors = {
      neovim = {
        enable = true;
        configRepo = "https://github.com/example/nvim-config.git";
        extraPackages = with pkgs; [ tree-sitter ripgrep fd ];
      };
      emacs = {
        enable = true;
        configRepo = "https://github.com/example/doom-emacs-config.git";
        extraPackages = with pkgs; [ ripgrep fd ispell ];
      };
      vscode = {
        enable = true;
      };
    };

    # General developer CLI tools.
    tools = {
      gemini = {
        enable = true;
      };
      opencode = {
        enable = true;
      };
      rtk = {
        enable = true;
      };
    };

    # System-level custom fonts.
    fonts = {
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.iosevka
      ];
    };
  };

  # ───────────────────────────────────────────────────────────────────────────
  # conf.systemServices — OS daemons, background services, hardware features
  # ───────────────────────────────────────────────────────────────────────────
  conf.systemServices = {
    # Linux bootloader configuration (ignored on Darwin).
    bootloader = {
      # method: (enum: bios|uefi) — "uefi" selects systemd-boot for UEFI systems.
      method = "uefi";
      program = "systemd-boot";
    };

    # GPU / Graphics hardware configuration.
    graphics = {
      enable = true;
      # vendor: (enum: intel|nvidia|amd|hybrid-intel-nvidia|hybrid-amd-nvidia|none)
      vendor = "intel";
    };

    # Power management (laptop profiles, thermals, sleep/wake).
    powerManagement = {
      enable = true;
    };

    # Containerisation runtimes.
    containerisation = {
      enable = true;
    };

    # Virtualisation hypervisors.
    virtualisation = {
      enable = true;
    };

    # Flatpak application runtime.
    flatpak = {
      enable = true;
    };

    # Homebrew integration (Darwin only).
    homebrew = {
      enable = false;
    };
  };
}
