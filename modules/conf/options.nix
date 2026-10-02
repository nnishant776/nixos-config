{ lib, pkgs, ... }:
let
  mkToggle = desc: lib.mkEnableOption desc;

  # Keyed by username: `conf.host.users.<name>`. There is deliberately no `name`
  # field — the attribute key is the username, so two users cannot silently
  # collapse into one. They used to, in four separate places, each doing
  # `listToAttrs (map (u: nameValuePair u.name ...))` over a free-form string.
  #
  # Only interactive accounts belong here. Service and system accounts are
  # created by the modules that need them, with isSystemUser — an invariant in
  # code, not a configuration knob.
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
          Grant this user administrative access: sudo (via wheel), plus the
          privilege-adjacent groups for whichever services the host enables —
          networkmanager, docker/podman, libvirtd/kvm.

          Off by default. Every one of those groups is root or near-root —
          membership of `docker` alone is equivalent to root, since a container
          can bind-mount the host filesystem — so they follow from this single
          flag rather than from `groups`. That keeps sudo-equivalent access
          declared in one place and makes it assertable.
        '';
      };
      groups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra groups for the user, beyond those derived from `privileged` and
          from the host's enabled services.

          Privilege-granting groups (wheel, docker, podman, libvirtd, kvm,
          networkmanager) are rejected here by an assertion — set
          `privileged = true` instead.
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
          Whether the *account itself* is created and maintained from this
          configuration, as opposed to only its home.

          `null` resolves by platform: true everywhere except Darwin, false on
          Darwin. That split reflects where accounts normally come from — a
          NixOS machine declares them, a Mac gets them from MDM or from whoever
          set the laptop up.

          Set explicitly to override the platform. `false` on Linux is for
          machines whose accounts arrive from a directory service; the account is
          left alone and only group membership is arranged.

          On Darwin, `true` puts the user in `users.knownUsers`, which is what
          lets nix-darwin create it — and also what lets it **delete** it:
          dropping a user from `conf.host.users` afterwards removes the account
          on the next activation for any uid above 501. nix-darwin's own
          documentation says not to put the administrator account in that list.
          `uid` is required in this case.
        '';
      };
      uid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Numeric user id. Only needed when `manageAccount` resolves true on
          Darwin, where nix-darwin has no default for it.

          It must match what the account already has, or nix-darwin prints
          "existing user has unexpected uid, skipping" and leaves it untouched.
          macOS hands out ids from 501 in creation order, so the same person can
          hold different ids on different machines unless MDM pins them.
        '';
      };
      gid = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Numeric primary group id. Optional — nix-darwin defaults to 20
          (`staff`), which is what a normal macOS account uses.
        '';
      };
      allowHomeManagement = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether this user is permitted to manage their own home.

          Off by default: the organisation manages the home, a system rebuild
          activates it, and the user's own ~/.config/home-manager/default.nix is
          **not read** — a rebuild evaluates as root, and depending on a
          user-writable file outside the flake would also mean a revision no
          longer determines the result. Personal configuration for such a user
          belongs in users/<name>/, tracked and reviewed.

          Granting it is a deliberate, reviewable act: the system stops
          activating that user's home, and this flake publishes
          `homeConfigurations.<user>@<host>` for them to activate themselves
          with `home-switch`. The organisation baseline, users/<name>/ and
          extraHomeConfig are still merged into it — what changes is who runs
          the activation, not whether policy reaches them.

          Exactly one of the two owns a home. They are disjoint by construction
          here, because two Home-Manager generations over one home directory
          delete each other's files on every activation.
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
          Interactive accounts on this machine, keyed by username. A device
          typically has the organisation's administrative account and the
          person's own account.

          Service and system accounts do not belong here — they are created by
          the modules that need them.
        '';
      };

      enableHomeManager = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether homes on this machine are managed by Home-Manager at all, by
          either the organisation or their users.

          A property of the machine's management model rather than of any one
          account, so it is set here and not per user. On by default; turning it
          off means this flake says nothing about any home on the host — no
          baseline is delivered and nothing is published for users to activate.

          Who manages an individual home is `users.<name>.allowHomeManagement`.
        '';
      };
      ldLibraries = {
        enable = lib.mkEnableOption "Enable LD libraries linkage";
        libraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = (import ./default-ld-libs.nix);
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
            Git remote this machine's configuration is deployed from. `os-install`
            clones it to `conf.management.localPath`, and `autoUpdate` syncs from
            it.

            null means the machine has no upstream: `os-install` leaves
            localPath empty and autoUpdate cannot be enabled.
          '';
        };
        ref = lib.mkOption {
          type = lib.types.str;
          default = "main";
          description = ''
            Branch or tag to track. This is the staging mechanism — point a
            canary ring at one ref and the rest of the fleet at another, and
            promote by moving the slower ref.
          '';
        };
      };

      localPath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/nixos";
        description = ''
          Where the configuration checkout lives on the machine. The default is
          what `nixos-rebuild` looks for when invoked with no arguments, so
          leaving it alone means a bare `nixos-rebuild switch` works.

          Kept as a git checkout rather than a copy so that the revision is a
          verifiable statement about what the machine should be running:
          `git -C <path> rev-parse HEAD`.
        '';
      };

      autoUpdate = {
        enable = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = ''
            Periodically sync `conf.management.repo` into `localPath` and
            rebuild from it.

            `null` resolves to whether this machine has an upstream at all: on
            when `conf.management.repo.url` is set, off when it is null. A fleet
            machine therefore syncs by virtue of having been given a repository,
            and a machine with no upstream is quietly left alone.

            Set `false` to opt a machine out while still pointing it at a
            repository — a development box you rebuild by hand, or one held back
            from a rollout. Setting `true` without a `repo.url` is an error
            rather than a no-op, since it asks for something unsatisfiable.
          '';
        };

        rollbackOnFailure = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            If activating the new configuration fails, return the system to the
            generation it was running.

            On by default because a half-activated system is what takes a machine
            out of reach: if the new generation breaks networking or sshd, the
            machine stops syncing and has no way back. Rolling back keeps it
            manageable so a later tick can retry.

            The cost is that a rolled-back machine deliberately does not match
            its checked-out revision, so it must be reported — otherwise it
            diverges silently forever. Turn this off if you would rather a
            failure be unmissable than survivable.
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
            Jitter added to each run so a fleet does not converge on the binary
            cache simultaneously.
          '';
        };

        allowReboot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Reboot after a switch when the new system's kernel or initrd differs
            from the running one. Off by default: the new userspace is active
            either way, and an unattended reboot is rarely what you want on a
            workstation.
          '';
        };

        resetLocalChanges = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Hard-reset localPath to the tracked ref before building, discarding
            local edits.

            On by default, deliberately: it is what makes the checked-out
            revision an honest description of the machine. With it off, a local
            edit silently parks the machine on a configuration no revision
            describes, and the sync quietly stops converging.
          '';
        };
      };
    };

    # ── Deployment Target ──
    platform = lib.mkOption {
      type = lib.types.enum [ "nixos" "darwin" "system-manager" ];
      description = ''
        Which kind of system this configuration is deployed to. Set by
        lib/mkHost.nix, which already decides between nixosSystem and
        darwinSystem — hosts do not set it.

        This exists because some differences are a property of the *deployment*
        rather than of the platform, and so cannot be expressed with
        `pkgs.stdenv.hostPlatform.isLinux`/`isDarwin`: NixOS and Ubuntu are both
        Linux, but on NixOS nix belongs to the system closure while on Ubuntu
        this configuration manages an externally installed nix.

        Use `pkgs.stdenv.hostPlatform.*` for platform differences and this for
        deployment-kind differences. Never inspect the evaluating machine —
        reading /etc/os-release describes the builder, not the target, and makes
        every build impure.

        No default on purpose: a missing value should fail loudly rather than
        silently assume a deployment kind.
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
