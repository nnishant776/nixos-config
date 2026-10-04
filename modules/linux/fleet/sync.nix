# Periodic sync of conf.fleet.repo into the local checkout, followed by a
# rebuild from it.
#
# Build and activation are separate steps: a build failure leaves the running
# system untouched (nothing to roll back), while an activation failure means
# the profile already moved and needs a rollback. Collapsing both into one
# `nixos-rebuild switch` would make the two failure modes indistinguishable.
{ config, lib, pkgs, ... }:
let
  cfg = config.conf.fleet;
  au = cfg.autoUpdate;

  syncScript = pkgs.writeShellApplication {
    name = "config-auto-update";
    runtimeInputs = [
      pkgs.git
      pkgs.nixos-rebuild
      config.nix.package
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      repo=${lib.escapeShellArg cfg.localPath}
      ref=${lib.escapeShellArg cfg.repo.ref}
      host=${lib.escapeShellArg config.conf.host.name}

      log() { echo "config-auto-update: $*"; }

      if [ ! -d "$repo/.git" ]; then
        log "no git checkout at $repo — refusing to sync"
        log "os-install populates it; see conf.fleet.repo"
        exit 1
      fi

      git -C "$repo" fetch --prune origin "$ref"
      target="$(git -C "$repo" rev-parse FETCH_HEAD)"
      before="$(git -C "$repo" rev-parse HEAD)"

      ${if au.resetLocalChanges then ''
        git -C "$repo" reset --hard "$target"
      '' else ''
        if ! git -C "$repo" merge --ff-only "$target"; then
          log "$repo has diverged from origin/$ref and cannot fast-forward"
          log "this machine is parked on a revision no upstream describes"
          exit 1
        fi
      ''}

      after="$(git -C "$repo" rev-parse HEAD)"
      log "revision $before -> $after (tracking $ref)"

      if ! newSystem="$(nix build --no-link --print-out-paths \
            "$repo#nixosConfigurations.$host.config.system.build.toplevel")"; then
        log "build of $after failed — running system left untouched"
        exit 1
      fi

      running="$(readlink -f /run/current-system)"
      if [ "$newSystem" = "$running" ]; then
        log "already running the configuration at $after"
        exit 0
      fi

      # Target this generation by number, not `--rollback` ("one back"), which
      # would quietly downgrade the machine if the switch failed before moving
      # the profile.
      systemProfile=/nix/var/nix/profiles/system
      previousLink="$(basename "$(readlink "$systemProfile")")"
      previousGen="''${previousLink#system-}"
      previousGen="''${previousGen%-link}"
      log "activating $newSystem (current generation $previousGen)"

      if ! nixos-rebuild switch --flake "$repo#$host"; then
        ${if au.rollbackOnFailure then ''
          log "activation failed — returning to generation $previousGen"
          if nix-env -p "$systemProfile" --switch-generation "$previousGen" \
             && "$systemProfile/bin/switch-to-configuration" switch; then
            log "rolled back to generation $previousGen; this machine no longer"
            log "matches $after and will show as drift until upstream is fixed"
          else
            log "ROLLBACK FAILED; the system may be in a mixed state"
          fi
        '' else ''
          log "activation failed at $after and rollbackOnFailure is off —"
          log "leaving the system as it is, which may be partially activated"
        ''}
        exit 1
      fi

      # Reported, not acted on: rolling back on any degraded state would put a
      # machine with one pre-existing failed unit into a rollback loop on every
      # tick. A real health gate would need to compare against a baseline.
      state="$(systemctl is-system-running || true)"
      log "system state after switch: $state"
      if [ "$state" != "running" ]; then
        systemctl --failed --no-legend --plain || true
      fi

      ${lib.optionalString au.allowReboot ''
        booted="$(readlink -f /run/booted-system/kernel /run/booted-system/initrd 2>/dev/null || true)"
        built="$(readlink -f "$newSystem/kernel" "$newSystem/initrd" 2>/dev/null || true)"
        if [ "$booted" != "$built" ]; then
          log "kernel or initrd changed — rebooting"
          systemctl reboot
        fi
      ''}

      log "done at $after"
    '';
  };
  # null means "sync if this machine has an upstream at all", so a fleet host
  # converges by virtue of having been given a repository and a standalone
  # machine is left alone. An explicit value wins either way.
  enabled =
    if au.enable != null then au.enable else cfg.repo.url != null;
in
{
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(au.enable == true && cfg.repo.url == null);
          message =
            "conf.fleet.autoUpdate.enable is true but"
            + " conf.fleet.repo.url is null: there is nothing to sync from."
            + " Leave enable unset to have it follow whether a repository is"
            + " configured.";
        }
      ];
    }

    (lib.mkIf (enabled && cfg.repo.url != null && config.conf.platform == "nixos") {

    systemd.services.config-auto-update = {
      description = "Sync ${cfg.localPath} from ${cfg.repo.ref} and rebuild";
      documentation = [ "https://github.com/nnishant776/nixos-config" ];

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # Required because this service is part of the configuration it
      # activates; otherwise switch-to-configuration restarts it mid-run and
      # the run is killed by its own success.
      restartIfChanged = false;

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe syncScript;
      };
    };

    systemd.timers.config-auto-update = {
      description = "Timer for ${cfg.localPath} configuration sync";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = au.dates;
        RandomizedDelaySec = au.randomizedDelaySec;
        # Machines that were off at the scheduled time still converge.
        Persistent = true;
      };
    };
    })
  ];
}
