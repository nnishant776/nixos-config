{ lib, pkgs, ... }:
let
  mkToggle = desc: lib.mkEnableOption desc;

  # Keyed by username, so the attribute name is the account name. Only
  # interactive accounts belong here; service accounts are created by the modules
  # that need them.
  userSubmodule = lib.types.submodule ({ name, ... }: {
    options = {
      fullName = lib.mkOption {
        type = lib.types.str;
        default = name;
        defaultText = lib.literalExpression "the attribute name";
        description = "User's full name. Defaults to the username.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "User's email address.";
      };
      privileged = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Grant this user administrative access: sudo through `wheel`, plus the
          privilege-adjacent groups for whichever services the host enables,
          namely networkmanager, docker, podman and libvirtd.

          Those groups all confer root or near-root access, so they follow from
          this one flag rather than being listed individually in `groups`.
        '';
      };
      groups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra groups for the user, beyond those derived from `privileged` and
          from the host's enabled services. The privilege-granting groups
          (wheel, docker, podman, libvirtd, networkmanager) are rejected here;
          set `privileged = true` instead.
        '';
      };
      initialHashedPassword = lib.mkOption {
        type = lib.types.str;
        default = "$y$j9T$Em3GOBdeSlR5rvnBakCQt1$MNH7/4KvTt423qqDDHsSUAz96SCUWm5AKMqjy5hzFS3";
        description = "Initial hashed password (change after install).";
      };
      manageAccount = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = ''
          Whether the account itself is created and maintained from this
          configuration, rather than only its home.

          `null` resolves to true on Linux and false on Darwin, where accounts
          normally come from MDM. An explicit value overrides that. `false` is
          not supported on Linux and is rejected by an assertion.

          Setting it true on Darwin adds the user to `users.knownUsers`, which is
          also nix-darwin's delete list: removing the user from
          `conf.host.users` later deletes the account on the next activation for
          any uid above 501. A `uid` is required in that case.
        '';
      };
      uid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Numeric user id, required when `manageAccount` resolves true on Darwin.

          It must match the id the account already has, or activation warns about
          an unexpected uid and leaves the user untouched. macOS assigns ids from
          501 in creation order, so one person can hold different ids on
          different machines unless MDM pins them.
        '';
      };
      gid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Numeric primary group id. Optional, since nix-darwin defaults to 20
          (`staff`), which is what a normal macOS account uses.
        '';
      };
      allowHomeManagement = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether this user manages their own home instead of the system doing
          it.

          Off by default, meaning a system rebuild activates the home and the
          user's own `~/.config/home-manager/home.nix` is not read at all.
          Personal configuration for such a user belongs in `users/<name>/`.

          Granting it stops the system activating that home and publishes
          `homeConfigurations.<user>@<host>` for the user to activate with
          `home-switch`. The baseline, `users/<name>/` and `extraHomeConfig` are
          still merged in either way; only the activation changes hands.
        '';
      };
      extraHomeConfig = lib.mkOption {
        type = lib.types.deferredModule;
        default = {};
        description = "Additional Home-Manager configuration for this user.";
      };
    };
  });

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
  options.conf = {
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
      users = lib.mkOption {
        type = lib.types.attrsOf userSubmodule;
        default = { };
        example = lib.literalExpression ''
          {
            orgadmin = { fullName = "Org Admin"; privileged = true; };
            alice = { fullName = "Alice"; allowHomeManagement = true; };
          }
        '';
        description = ''
          Interactive accounts on this machine, keyed by username. Service and
          system accounts do not belong here; they are created by the modules
          that need them.
        '';
      };

      enableHomeManager = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether homes on this machine are managed at all, by either the system
          or their users. On by default; turning it off means nothing is
          delivered to any home on the host and nothing is published for users to
          activate.

          Who manages an individual home is `users.<name>.allowHomeManagement`.
        '';
      };
      ldLibraries = {
        enable = lib.mkEnableOption "Enable LD libraries linkage";
        libraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = ''
            Shared libraries exported to nix-ld, for running downloaded
            binaries that expect a conventional filesystem. Replaces the
            curated default set in modules/conf/default-ld-libs.nix. Leave it
            empty to keep that set and use `extraLibraries` to add to it.
          '';
        };
        extraLibraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = ''
            Shared libraries appended to whichever set `libraries` resolves to,
            so the curated default is kept. The development, graphics,
            multimedia and virtualisation groups contribute their own
            `nix-ldLibraries` on top of this.
          '';
        };
      };
    };

    # ── Fleet Management ──
    management = {
      repo = {
        url = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "https://github.com/org/nixos-config.git";
          description = ''
            Git remote this machine's configuration is deployed from.
            `os-install` clones it to `conf.management.localPath` and
            `autoUpdate` syncs from it. `null` means the machine has no upstream,
            in which case the checkout is left empty and automatic updates stay
            off.
          '';
        };
        ref = lib.mkOption {
          type = lib.types.str;
          default = "main";
          description = ''
            Branch or tag to track. Point a canary group of machines at one ref
            and the rest at another to stage a rollout.
          '';
        };
      };

      localPath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/nixos";
        description = ''
          Where the configuration checkout lives on the machine. The default is
          where `nixos-rebuild` looks when given no flake, so leaving it alone
          means a bare `nixos-rebuild switch` works.

          It is a git checkout rather than a copy, so `git -C <path> rev-parse
          HEAD` states which revision the machine should be running.
        '';
      };

      autoUpdate = {
        enable = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = ''
            Periodically sync `conf.management.repo` into `localPath` and
            rebuild from it.

            `null` means on when `conf.management.repo.url` is set and off when
            it is not, so a machine syncs by virtue of having been given a
            repository. Set `false` to opt a machine out while still pointing it
            at one. Setting `true` without a `repo.url` is an error.
          '';
        };

        rollbackOnFailure = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            If activating the new configuration fails, return the system to the
            generation it was running. On by default, so that a machine whose new
            generation breaks networking can still be reached and retried.

            Note that a rolled-back machine no longer matches its checked-out
            revision until upstream is fixed, which is a condition worth
            reporting. Turn this off to leave a failed activation in place
            instead.
          '';
        };

        dates = lib.mkOption {
          type = lib.types.str;
          default = "04:00";
          description = "systemd OnCalendar expression for the sync timer.";
        };

        randomizedDelaySec = lib.mkOption {
          type = lib.types.int;
          default = 1800;
          description = ''
            Jitter added to each run so that a fleet does not hit the binary cache
            simultaneously.
          '';
        };

        allowReboot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Reboot after a switch when the new kernel or initrd differs from the
            running one. Off by default, since the new userspace is active either
            way and an unattended reboot is rarely wanted on a workstation.
          '';
        };

        resetLocalChanges = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Hard-reset `localPath` to the tracked ref before building, discarding
            any local edits. On by default, so that the checked-out revision
            always describes the machine. With it off, a machine that has
            diverged stops converging instead.
          '';
        };
      };
    };

    # ── Deployment Target ──
    platform = lib.mkOption {
      type = lib.types.enum [ "nixos" "darwin" "system-manager" ];
      description = ''
        Which kind of system this configuration is deployed to. Set by
        `lib/mkHost.nix`; hosts do not set it.

        Use it for differences that belong to the deployment rather than the
        platform, such as whether nix is part of the system closure, and use
        `pkgs.stdenv.hostPlatform.isLinux`/`isDarwin` for the rest. There is no
        default, so a missing value fails rather than being assumed.
      '';
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
      environments = {
        gnome = {
          enable = mkToggle "Enable the GNOME desktop environment";
        };
        hyprland = {
          enable = mkToggle "Enable the Hyprland desktop environment";
          shell = lib.mkOption {
            type = lib.types.enum [ "none" "caelestia" "noctalia" "dms" ];
            default = "none";
            description = "Optional custom shell for Hyprland.";
          };
        };
        sway = {
          enable = mkToggle "Enable the Sway desktop environment";
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
        method = lib.mkOption {
          type = lib.types.enum [ "bios" "uefi" ];
          default = "uefi";
          description = "Select a boot method (BIOS or UEFI)";
        };
        program = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum ["systemd-boot" "grub" "uboot"]);
          default = "systemd-boot";
        };
        allowEFIVariableEdit = lib.mkEnableOption "Allow bootloader to touch EFI variables";
      };

      networking = {
        enable = mkToggle "Enable networking and NetworkManager";
        wifi.enable = mkToggle "Enable WiFi backend";
        bluetooth.enable = mkToggle "Enable Bluetooth backend";
        firewall = {
          enable = mkToggle "Enable network firewall";
          config = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Network firewall configuration";
          };
        };
      };

      sharing = {
        enable = mkToggle "Enable sharing";
        ssh = {
          enable = mkToggle "Enable SSH service";
          config = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "SSH server configuration";
          };
        };
      };

      multimedia = {
        enable = mkToggle "Enable audio/video stack";
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Extra audio/video multimedia packages.";
        };
        nix-ldLibraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "Runtime shared libraries exported to nix-ld for audio/video.";
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
        cue    = mkSdkGroup "Cuelang tools";
        lua    = mkSdkGroup "Lua SDK (lua, lua-language-server)";
      };

      fonts = {
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "List of fonts packages to install";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
          description = "List of additional fonts packages to install";
        };
      };

      editors = {
        neovim = mkEditorGroup "Neovim";
        emacs  = mkEditorGroup "Emacs";
        vscode = mkEditorGroup "VSCode";
      };

      tools = {
        gemini = mkToolGroup "Gemini / Antigravity CLI";
        opencode = mkToolGroup "OpenCode CLI";
        rtk    = mkToolGroup "RTK CLI";
      };
    };
  };
}
