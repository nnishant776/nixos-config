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
    name = "example";
    timezone = "Asia/Kolkata";
    locale = "en_IN";

    # `enableHomeManager` is the host-level switch for whether home-manager
    # manages any user's home on this machine at all — on by default, opt
    # out for service/headless accounts. Shown explicitly here since this is
    # the reference host.
    enableHomeManager = true;

    # conf.host.users — accounts on this host, keyed by username
    # (attrsOf userSubmodule). Below: an organisation administrative account
    # plus an ordinary device user.
    users = {
      # conf.host.users.admin — organisation administrative account.
      admin = {
        fullName = "Reference Admin";
        email = "admin@example.com";
        # `privileged` grants sudo via wheel, plus the privilege-adjacent groups
        # (networkmanager, docker/podman, libvirtd/kvm, etc.) derived from
        # whichever services this host enables. `groups` is only for extra,
        # non-privilege memberships.
        privileged = true;
        # `initialHashedPassword` uses mkpasswd format; here we only show a placeholder.
        initialHashedPassword = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
        # `allowHomeManagement` decides *who* manages it. Off by default, meaning
        # the organisation does: a system rebuild activates the home and the
        # user's own ~/.config/home-manager is not read. Setting it true is a
        # reviewable grant — the system stops activating that home and the user
        # activates `homeConfigurations.<user>@<host>` themselves with
        # `home-switch`. Either way the organisation baseline, users/<name>/ and
        # extraHomeConfig are merged in.
        allowHomeManagement = false;
        # conf.host.users.admin.extraHomeConfig — extra home-manager module for this user.
        extraHomeConfig = {
          programs.starship.enable = true;
        };
      };

      # conf.host.users.bob — ordinary device user.
      bob = {
        fullName = "Bob Example";
        email = "bob@example.com";
        # Ordinary non-admin user: no sudo, and network access limited to the
        # narrow `network-users` permissions rather than the full
        # `networkmanager` group.
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

    # Per-environment toggles. Enabling several makes them ALL available as
    # session choices at the greeter — it does not force a single choice on
    # users, they pick whichever session they want at login.
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
