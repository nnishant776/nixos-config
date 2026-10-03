# NixOS / nix-darwin Configuration Flake

A multi-platform configuration flake for NixOS, macOS and Home Manager
environments. Machines are declared under `hosts/`, per-user configuration under
`users/`, and behaviour is driven by the `conf.*` option tree. Role [profiles](#profiles)
provide defaults that any host can override.

## Repository Layout

```
├── flake.nix                        # entry point; discovers hosts/ and users/
├── lib/
│   ├── mkHost.nix                   # host factory (NixOS / nix-darwin)
│   ├── buildUser.nix                # assembles a user's Home Manager modules
│   ├── mkUser.nix                   # standalone Home Manager builder
│   └── flakeLib.nix                 # helpers shared by this flake's modules
├── hosts/<hostname>/                # one directory per machine, auto-discovered
│   ├── hardware-configuration.nix   # Linux only, from nixos-generate-config
│   └── default.nix                  # nixpkgs.hostPlatform and conf.* settings
├── users/<username>/                # optional per-user configuration
│   └── default.nix                  # merged into that user's home, both paths
└── modules/
    ├── core/                        # cross-platform baseline and dev tooling
    ├── conf/                        # the conf.* option tree, profiles, implications
    ├── user/                        # Home Manager baseline for managed users
    └── system/
        ├── linux/                   # NixOS implementation of conf.*
        └── darwin/                  # macOS implementation of conf.*
```

## Usage

### Adding a machine

Create `hosts/<hostname>/default.nix` with `nixpkgs.hostPlatform` and the
machine's `conf.*` settings. No change to `flake.nix` is needed. The directory
name must be exactly the machine's hostname.

### Building and switching a system

```bash
nixos-rebuild  switch --flake .#<hostname>     # Linux
darwin-rebuild switch --flake .#<hostname>     # macOS
system-switch                                  # wrapper; defaults to /etc/nixos and this host
```

On a machine whose configuration lives in `/etc/nixos`, `nixos-rebuild switch`
with no arguments works, because that is where it looks when given no flake.

### Switching a home configuration

Only users granted `allowHomeManagement` have a home configuration to activate.
For everyone else a system rebuild activates the home.

```bash
home-switch                                    # this user, /etc/nixos, this host
home-switch <username> <flake path> <host>     # explicit
```

### Installing a machine

```bash
nix run .#os-install -- <hostname>
```

This partitions the disks with disko, installs the system, and clones
`conf.management.repo.url` into `conf.management.localPath` pinned to the
installed revision.

### Checking the flake

```bash
nix run .#check-purity                         # every system output must evaluate without --impure
nix eval .#nixosConfigurations.<host>.config.conf.systemServices.graphics.vendor
```

## Configuration

### `conf.host`

| Option | Type | Default | Description |
|---|---|---|---|
| `host.name` | str | `"localhost"` | Hostname. Must equal the host directory name |
| `host.timezone` | str | `"Asia/Kolkata"` | Timezone |
| `host.locale` | str | `"en_IN"` | Locale; also sets the `LC_*` variables |
| `host.users` | attrsOf user | `{}` | Interactive accounts, keyed by username |
| `host.enableHomeManager` | bool | `true` | Whether any home on this machine is managed |
| `host.ldLibraries.enable` | toggle | `false` | Export shared libraries to nix-ld |
| `host.ldLibraries.libraries` | listOf package | `[]` | **Replaces** the curated default set |
| `host.ldLibraries.extraLibraries` | listOf package | `[]` | **Appends** to the default set |

Each entry in `conf.host.users` takes these fields:

| Field | Type | Default | Description |
|---|---|---|---|
| `fullName` | str | *the username* | Display name |
| `email` | str | `""` | Email address |
| `privileged` | bool | `false` | Grants sudo through `wheel`, plus the privilege-adjacent groups for whichever services the host enables |
| `groups` | listOf str | `[]` | Extra groups. Privilege-granting groups are rejected here |
| `initialHashedPassword` | str | *(placeholder)* | Initial password, in `mkpasswd` format |
| `allowHomeManagement` | bool | `false` | Lets this user manage their own home instead of the system doing it |
| `manageAccount` | nullOr bool | `null` | Whether the account itself is created here. `null` means true on Linux and false on macOS |
| `uid` | nullOr int | `null` | Numeric user id. Required on macOS when `manageAccount` is true |
| `gid` | nullOr int | `null` | Numeric primary group id. Defaults to `20` (`staff`) on macOS |
| `extraHomeConfig` | deferredModule | `{}` | Additional Home Manager configuration for this user |

A user's home configuration is assembled from the baseline in `modules/user/`,
anything in `users/<username>/default.nix`, their `extraHomeConfig`, and — only
for a user with `allowHomeManagement` — their own
`~/.config/home-manager/home.nix`.

### `conf.management`

| Option | Type | Default | Description |
|---|---|---|---|
| `management.repo.url` | nullOr str | `null` | Git remote the machine is deployed from |
| `management.repo.ref` | str | `"main"` | Branch or tag to track |
| `management.localPath` | str | `"/etc/nixos"` | Where the configuration checkout lives |
| `management.autoUpdate.enable` | nullOr bool | `null` | Periodic sync and rebuild. `null` means on when `repo.url` is set |
| `management.autoUpdate.dates` | str | `"04:00"` | systemd `OnCalendar` expression |
| `management.autoUpdate.randomizedDelaySec` | int | `1800` | Jitter, so a fleet does not sync simultaneously |
| `management.autoUpdate.allowReboot` | bool | `false` | Reboot when the kernel or initrd changed |
| `management.autoUpdate.resetLocalChanges` | bool | `true` | Discard local edits in the checkout before building |
| `management.autoUpdate.rollbackOnFailure` | bool | `true` | Return to the previous generation if activation fails |

Point a canary group of machines at one `ref` and the rest at another, then
promote a release by moving the slower ref.

### `conf.platform`

One of `nixos`, `darwin` or `system-manager`. Set by `lib/mkHost.nix`; hosts do
not set it. Use it for differences that belong to the deployment rather than the
platform, and `pkgs.stdenv.hostPlatform.isLinux`/`isDarwin` for the rest.

### `conf.profile`

One of `minimal`, `server`, `workstation`, `developer`, `gaming` or `embedded`.
See [Profiles](#profiles).

### `conf.desktop`

| Option | Type | Default | Description |
|---|---|---|---|
| `desktop.enable` | toggle | `false` | GUI stack and greeter |
| `desktop.environments.gnome.enable` | toggle | `false` | Make GNOME available |
| `desktop.environments.hyprland.enable` | toggle | `false` | Make Hyprland available |
| `desktop.environments.hyprland.shell` | enum: `none`/`caelestia`/`noctalia`/`dms` | `"none"` | Optional Hyprland shell |
| `desktop.environments.sway.enable` | toggle | `false` | Make Sway available |
| `desktop.packages` | listOf package | `[]` | Replaces the default desktop application set |
| `desktop.extraPackages` | listOf package | `[]` | Appends to the desktop application set |

Enabling several environments makes them all available as session choices at the
greeter. Enabling the desktop also implies multimedia, graphics, power
management and flatpak, weakly, so a host can still turn any of them off.

The greeter is ReGreet running under `cage`, configured for every host with a
desktop. It lists whichever sessions the host installs. Customisation goes
through the upstream options — `programs.regreet.settings`, `extraCss`,
`cageArgs`, and the theme, icon theme, cursor theme and font settings.

### `conf.systemServices`

| Option | Type | Default | Description |
|---|---|---|---|
| `systemServices.bootloader.method` | enum: `bios`/`uefi` | `"uefi"` | Boot method |
| `systemServices.bootloader.program` | nullOr enum: `systemd-boot`/`grub`/`uboot` | `"systemd-boot"` | Bootloader |
| `systemServices.bootloader.allowEFIVariableEdit` | toggle | `false` | Allow writing EFI variables |
| `systemServices.networking.enable` | toggle | `false` | NetworkManager |
| `systemServices.networking.wifi.enable` | toggle | `false` | WiFi backend |
| `systemServices.networking.bluetooth.enable` | toggle | `false` | Bluetooth backend |
| `systemServices.multimedia.enable` | toggle | `false` | Audio and video stack |
| `systemServices.graphics.enable` | toggle | `false` | Hardware acceleration |
| `systemServices.graphics.vendor` | enum: `intel`/`amd`/`nvidia` | `"intel"` | Driver selection |
| `systemServices.powerManagement.enable` | toggle | `false` | Power management daemons |
| `systemServices.containerisation.enable` | toggle | `false` | Docker and Podman |
| `systemServices.virtualisation.enable` | toggle | `false` | KVM, QEMU, libvirt, virt-manager |
| `systemServices.flatpak.enable` | toggle | `false` | Flatpak support |
| `systemServices.homebrew.enable` | toggle (macOS) | `false` | Homebrew integration |
| `systemServices.homebrew.brews` / `.casks` | listOf str | `[]` | Formulae and casks |
| `systemServices.homebrew.masApps` | attrsOf int | `{}` | Mac App Store applications, name to id |
| `systemServices.homebrew.onActivation.cleanup` | enum: `none`/`uninstall`/`zap` | `"none"` | Cleanup mode |

The multimedia, graphics and virtualisation groups each also take
`extraPackages` and `nix-ldLibraries`; containerisation takes `extraPackages`.

### `conf.development`

| Option | Type | Default | Description |
|---|---|---|---|
| `development.enable` | toggle | `false` | Master switch for the development stack |
| `development.extraPackages` | listOf package | `[]` | Always-installed extras |

Each SDK (`sdk.base`, `sdk.cpp`, `sdk.go`, `sdk.rust`, `sdk.python`, `sdk.java`,
`sdk.nix`, `sdk.cue`, `sdk.lua`) and each tool (`tools.gemini`,
`tools.opencode`, `tools.rtk`) shares one shape:

| Field | Type | Default | Description |
|---|---|---|---|
| `enable` | toggle | `false` | Install this group |
| `packages` | listOf package | `[]` | **Replaces** the curated default set |
| `extraPackages` | listOf package | `[]` | **Appends** to the default set |
| `nix-ldLibraries` | listOf package | `[]` | Runtime libraries exported to nix-ld |

Editors take the same fields. `editors.neovim` and `editors.emacs` additionally
accept `configPath` for a local path and `configRepo` for a remote one.

## Profiles

A profile is a role preset. Every value it sets uses `lib.mkDefault`, so a plain
assignment in a host configuration always wins without any special syntax.

| Profile | Enables |
|---|---|
| `minimal` | networking |
| `server` | networking, containerisation, virtualisation, development with `sdk.base` |
| `workstation` | networking and wifi, multimedia, graphics, desktop, power management, flatpak |
| `developer` | the workstation set, plus containerisation, virtualisation and development with all SDKs, neovim and emacs |
| `gaming` | the workstation set |
| `embedded` | networking, development with `sdk.base` and `sdk.cpp` |

`developer` enables every SDK and both neovim and emacs, but leaves
`editors.vscode` and all of `tools.*` off. Add game launchers to `gaming` with
`desktop.extraPackages`.

```nix
# hosts/my-laptop/default.nix
{ pkgs, ... }: {
  nixpkgs.hostPlatform = "x86_64-linux";

  conf = {
    profile = "developer";

    host = {
      name = "my-laptop";
      users.alice = {
        fullName = "Alice";
        privileged = true;
        allowHomeManagement = true;
      };
    };

    systemServices = {
      containerisation.enable = false;        # the preset enables it
      graphics.vendor = "nvidia";
    };

    desktop = {
      enable = true;
      environments.hyprland = {
        enable = true;
        shell = "caelestia";
      };
      extraPackages = with pkgs; [ discord spotify ];
    };

    development.sdk.go.enable = false;
  };
}
```

### Overriding values

| You want | Use |
|---|---|
| Override a value a module set with `lib.mkDefault`, including every profile preset | a plain assignment |
| Override a value a module set with a plain assignment | `lib.mkForce`; two plain definitions are a conflict, not a win |
| Beat another module's `lib.mkForce` | `lib.mkOverride 40`; two `mkForce` definitions conflict |
| Append to a list | `extraPackages`, or a plain list assignment, since list definitions concatenate |

## Caveats

**New files must be added to git.** Flakes only see files git knows about, so a
new `users/<name>/default.nix` or module is silently ignored until it is at least
`git add`ed. There is no error.

**A host directory name must equal both `conf.host.name` and the machine's
hostname.** An assertion enforces the first part. The reason for the second is
that `nixos-rebuild` with no arguments resolves `#$(hostname)`.

**A home has exactly one owner.** By default the organisation owns it and a
system rebuild activates it, in which case the user's own
`~/.config/home-manager/home.nix` is not read at all — silently. Personal
configuration for such a user belongs in `users/<username>/`. Granting
`allowHomeManagement` moves ownership to the user, who then activates it with
`home-switch`; the system stops doing so. Do not try to arrange both: two Home
Manager generations over one home directory remove each other's files on every
activation.

**Revoking `allowHomeManagement` is destructive.** The next rebuild activates the
organisation's home, and files the user's own generation placed are removed.
Conflicting files are moved aside rather than deleted, with a suffix naming the
flake revision that displaced them.

**`host.enableHomeManager = false` means nothing manages the home**, neither the
organisation nor the user.

**On macOS, accounts are left alone by default.** `manageAccount` resolves to
false there, so nix-darwin does not touch the account and only the home is
configured. Setting it true adds the user to `users.knownUsers`, which is also
nix-darwin's delete list — removing that user from `conf.host.users` afterwards
deletes the account on the next activation for any uid above 501. A `uid` is
required in that case and must match the account's existing id, or activation
warns about an unexpected uid and skips the user. nix-darwin's own documentation
advises against managing the administrator account this way.

**On Linux, `manageAccount = false` is not supported** and is rejected by an
assertion.

**System outputs must evaluate without `--impure`.** `nix run .#check-purity`
enforces it. Reading machine state during evaluation, such as `/etc/os-release`,
describes the builder rather than the target and breaks automated rebuilds. Use
`conf.platform` instead. `home-switch` does need `--impure`, because a user's own
configuration lives outside the flake.

**Automatic updates discard local edits.** With `resetLocalChanges` on, which is
the default, the checkout is hard reset to the tracked ref before building, so
anything edited in place on the machine is lost. With it off, a machine that has
diverged stops converging instead.

**A rolled-back machine does not match its revision.** If activation fails and
`rollbackOnFailure` is on, the machine returns to its previous generation while
the checkout stays at the new one. The two disagree until upstream is fixed,
which is why the condition needs reporting rather than silence.

**X11 sessions need `services.xserver.enable`.** The greeter is only given the X
session directory and launch wrapper when an X server is configured. None of the
environments offered here currently provides an X11 session.

**Virtual machines do not need `libvirtd`.** An unprivileged user can run
hardware-accelerated VMs through `qemu:///session`, plain `qemu`, or
`nixos-rebuild build-vm`, because `/dev/kvm` is world-accessible. Membership of
`libvirtd` allows defining a VM with host disk passthrough, which is equivalent
to reading any file on the host as root, so it is only granted to privileged
users.

**Installing from a working tree with uncommitted changes cannot pin the
checkout.** `os-install` warns and leaves `/etc/nixos` at the tip of the tracked
ref, which may not match the system it just installed.

## Inputs

| Input | Ref | Purpose |
|---|---|---|
| `nixpkgs` | nixos-26.05 | base packages and modules |
| `nixpkgs-unstable` | nixos-unstable | occasional newer packages |
| `nix-darwin` | nix-darwin-26.05 | macOS support |
| `home-manager` | master | per-user environments |
| `dms` | stable | DankMaterialShell |
| `noctalia` / `noctalia-greeter` | main | Noctalia shell and greeter |
| `caelestia-shell` | main | Caelestia shell |
| `disko` | master | declarative disk partitioning |
| `apple-fonts` | main | SF Pro and SF Mono |
