{ lib, ... }: {
  options.conf.fleet = {
    repo = {
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "https://github.com/org/nixos-config.git";
        description = ''
          Git remote this machine's configuration is deployed from.
          `os-install` clones it to `conf.fleet.localPath` and `autoUpdate`
          syncs from it. `null` means the machine has no upstream, in which case
          the checkout is left empty and automatic updates stay off.
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
          Periodically sync `conf.fleet.repo` into `localPath` and rebuild from
          it.

          `null` means on when `conf.fleet.repo.url` is set and off when it is
          not, so a machine syncs by virtue of having been given a repository.
          Set `false` to opt a machine out while still pointing it at one.
          Setting `true` without a `repo.url` is an error.
        '';
      };
      rollbackOnFailure = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          If activating the new configuration fails, return the system to the
          generation it was running. On by default, so that a machine whose new
          generation breaks networking can still be reached and retried.

          A rolled-back machine no longer matches its checked-out revision until
          upstream is fixed, which is a condition worth reporting. Turn this off
          to leave a failed activation in place instead.
        '';
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "04:00";
        description = "systemd `OnCalendar` expression for the sync timer.";
      };
      randomizedDelaySec = lib.mkOption {
        type = lib.types.int;
        default = 1800;
        description = "Jitter added to each run so that a fleet does not hit the binary cache simultaneously.";
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
}
