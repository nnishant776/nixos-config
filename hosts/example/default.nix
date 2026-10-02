# Reference host, for looking up how an option is written rather than for
# deployment. It sets a representative value for most of the `conf.*` tree, so
# it pulls in a lot of packages — every SDK, two desktop environments and both
# container and VM stacks. Copy from it; do not switch to it.
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
    name = "example";
    timezone = "Asia/Kolkata";
    locale = "en_IN";

    # Host-level switch for whether any home here is managed at all.
    enableHomeManager = true;

    # Accounts on this host, keyed by username: an administrative account and an
    # ordinary device user.
    users = {
      admin = {
        fullName = "Reference Admin";
        email = "admin@example.com";
        # Grants sudo, plus the privilege-adjacent groups for whichever services
        # this host enables.
        privileged = true;
        # mkpasswd format; a placeholder here.
        initialHashedPassword = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
        # Left off, so a system rebuild activates this home and the user's own
        # ~/.config/home-manager is not read.
        allowHomeManagement = false;
        # Extra Home Manager configuration for this user.
        extraHomeConfig = {
          programs.starship.enable = true;
        };
      };

      bob = {
        fullName = "Bob Example";
        email = "bob@example.com";
        # No sudo, and network access limited to the narrow `network-users`
        # permissions rather than the full `networkmanager` group.
        privileged = false;
        extraHomeConfig = {};
      };
    };

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

    # Enabling several makes them all available as session choices at the greeter.
    environments = {
      gnome = {
        enable = true;
      };
      hyprland = {
        enable = true;
        # shell: (enum: none|caelestia|noctalia|dms)
        shell = "dms";
      };
      sway = {
        enable = false;
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
