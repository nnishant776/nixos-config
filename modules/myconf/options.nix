{ lib, pkgs, ... }:
let
  mkToggle = desc: lib.mkEnableOption desc;

  userSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username.";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        default = "Administrator";
        description = "User's full name.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "User's email address.";
      };
      groups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "wheel" ];
        description = "Extra groups for the user.";
      };
      initialHashedPassword = lib.mkOption {
        type = lib.types.str;
        default = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
        description = "Initial hashed password (change after install).";
      };
      enableHomeManager = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Home-Manager configuration for this user.";
      };
      extraHomeConfig = lib.mkOption {
        type = lib.types.deferredModule;
        default = {};
        description = "Additional Home-Manager configuration for this user.";
      };
    };
  };

  mkSdkGroup = desc: {
    enable = mkToggle "Enable ${desc}";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Default packages for ${desc}.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages for ${desc}.";
    };
    nix-ldLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Runtime shared libraries exported to nix-ld for ${desc}.";
    };
  };

  mkEditorGroup = desc: {
    enable = mkToggle "Enable ${desc}";
    configPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Local path for ${desc} configuration.";
    };
    configRepo = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Remote repository for ${desc} configuration.";
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Default packages for ${desc}.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages for ${desc}.";
    };
    nix-ldLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Runtime shared libraries exported to nix-ld for ${desc}.";
    };
  };

  mkToolGroup = desc: {
    enable = mkToggle "Enable ${desc}";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Default packages for ${desc}.";
    };
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages for ${desc}.";
    };
    nix-ldLibraries = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Runtime shared libraries exported to nix-ld for ${desc}.";
    };
  };

in {
  options.myconf = {
    # ── Host Configuration ──
    host = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Hostname for this machine.";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        default = "Asia/Kolkata";
        description = "Timezone string.";
      };
      locale = lib.mkOption {
        type = lib.types.str;
        default = "en_IN";
        description = "Default locale.";
      };
      adminUser = lib.mkOption {
        type = userSubmodule;
        default = {};
        description = "Primary administrative user configuration.";
      };
      extraUsers = lib.mkOption {
        type = lib.types.listOf userSubmodule;
        default = [];
        description = "Additional system user accounts.";
      };
    };

    # ── System Profile Preset ──
    profile = lib.mkOption {
      type = lib.types.enum [
        "minimal"
        "server"
        "workstation"
        "developer"
        "gaming"
        "embedded"
      ];
      default = "minimal";
      description = "High-level role preset that sets subsystem defaults.";
    };

    # ── Desktop & GUI ──
    desktop = {
      enable = mkToggle "Enable GUI desktop environments and display managers";
      environment = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "gnome" "hyprland" "sway" "all" ]);
        default = null;
        description = "Desktop environment to activate.";
      };
      environments = {
        hyprland = {
          shell = lib.mkOption {
            type = lib.types.enum [ "none" "caelestia" "noctalia" ];
            default = "none";
            description = "Optional custom shell for Hyprland.";
          };
        };
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Default desktop applications and tools.";
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Extra desktop packages to install.";
      };
    };

    # ── System Services & Infrastructure ──
    systemServices = {
      bootloader = {
        program = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum ["systemd-boot" "grub" "uboot"]);
          default = "systemd-boot";
        };
        allowEFIVariableEdit = lib.mkEnableOption "Allow bootloader to touch EFI variables";
      };

      networking = {
        enable = mkToggle "Enable networking and NetworkManager";
        wifi.enable = mkToggle "Enable WiFi backend";
      };

      audio = {
        enable = mkToggle "Enable PipeWire audio stack";
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Extra audio/multimedia packages.";
        };
        nix-ldLibraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Runtime shared libraries exported to nix-ld for audio.";
        };
      };

      graphics = {
        enable = mkToggle "Enable hardware graphics acceleration";
        vendor = lib.mkOption {
          type = lib.types.enum [ "intel" "amd" "nvidia" ];
          default = "intel";
          description = "GPU vendor for selecting drivers.";
        };
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Extra graphics packages.";
        };
        nix-ldLibraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Runtime shared libraries exported to nix-ld for graphics.";
        };
      };

      powerManagement = {
        enable = mkToggle "Enable power management daemon (tuned/upower)";
      };

      containerisation = {
        enable = mkToggle "Enable Docker and Podman container engines";
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Extra containerisation packages.";
        };
      };

      virtualisation = {
        enable = mkToggle "Enable hypervisor and virtualisation (KVM, QEMU, Libvirt, Virt-Manager)";
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Extra virtualisation packages.";
        };
        nix-ldLibraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Runtime shared libraries exported to nix-ld for virtualisation.";
        };
      };

      homebrew = {
        enable = mkToggle "Enable Homebrew package manager integration (Darwin only)";
        brews = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Formulae to install via Homebrew.";
        };
        casks = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Casks to install via Homebrew.";
        };
        masApps = lib.mkOption {
          type = lib.types.attrsOf lib.types.int;
          default = {};
          description = "Mac App Store applications to install (Name = AppID).";
        };
        onActivation = {
          autoUpdate = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Auto-update Homebrew formulae on system activation.";
          };
          cleanup = lib.mkOption {
            type = lib.types.enum [ "none" "uninstall" "zap" ];
            default = "none";
            description = "Homebrew bundle cleanup mode.";
          };
          upgrade = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Auto-upgrade Homebrew packages on system activation.";
          };
        };
      };

      flatpak = {
        enable = mkToggle "Enable Flatpak support";
      };
    };

    # ── Development Tooling ──
    development = {
      enable = mkToggle "Enable development tooling stack";
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Extra top-level development packages.";
      };

      sdk = {
        base   = mkSdkGroup "Base SDK (git, gh, tmux, nodejs, clang)";
        cpp    = mkSdkGroup "C/C++ SDK (clang-tools, cmake)";
        go     = mkSdkGroup "Go SDK";
        rust   = mkSdkGroup "Rust SDK (rustup)";
        python = mkSdkGroup "Python SDK (python3)";
        java   = mkSdkGroup "Java SDK (Zulu JDK)";
        nix    = mkSdkGroup "Nix Tooling (nil LSP)";
        lua    = mkSdkGroup "Lua SDK (lua, lua-language-server)";
      };

      editors = {
        neovim = mkEditorGroup "Neovim";
        emacs  = mkEditorGroup "Emacs";
        vscode = {
          enable = mkToggle "Enable VSCode";
          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Default packages for VSCode.";
          };
          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Extra packages for VSCode.";
          };
          nix-ldLibraries = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
            description = "Runtime shared libraries exported to nix-ld for VSCode.";
          };
        };
      };

      tools = {
        gemini = mkToolGroup "Gemini / Antigravity CLI";
        rtk    = mkToolGroup "RTK CLI";
      };
    };
  };
}
