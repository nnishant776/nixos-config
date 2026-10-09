# Self-managed homes are the only ones a system rebuild does not activate, so
# they are the only ones that can fall behind the organisation's configuration.
# After every switch, and at every graphical login, each such user's session
# compares the revision stamped into their active Home Manager generation with
# the one the system was built from, and raises a persistent critical
# notification when they differ. The check reads the generation in the Nix
# store, not a file in the home directory.
{ config, lib, pkgs, inputs, ... }:
let
  revision = inputs.self.rev or inputs.self.dirtyRev or "unknown";

  selfManaged = lib.attrNames (lib.filterAttrs
    (_: u: config.conf.users.manageHomes && u.selfManagedHome)
    config.conf.users.accounts);

  check = pkgs.writeShellApplication {
    name = "org-home-drift";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify pkgs.systemd ];
    text = ''
      user="$(id -un)"
      selfManaged=" ${lib.concatStringsSep " " selfManaged} "
      case "$selfManaged" in
        *" $user "*) ;;
        *) exit 0 ;;   # organisation-managed: the rebuild already activated it
      esac

      expected="$(cat /etc/org/revision 2>/dev/null || echo unknown)"
      [ "$expected" = unknown ] && exit 0   # nothing trustworthy to compare with

      generation="$HOME/.local/state/nix/profiles/home-manager"
      actual="$(cat "$generation/home-files/.config/org/revision" 2>/dev/null || echo none)"
      [ "$actual" = "$expected" ] && exit 0

      # Recorded in the journal for later reporting; the notification is for
      # the person at the keyboard.
      echo "home drift: user=$user home=$actual system=$expected"

      # The bus is up before graphical-session.target, but the notification
      # daemon is whatever the session runs (a shell, gnome-shell, mako, ...),
      # often not a systemd unit, and it claims its name a moment later. Wait
      # for the name rather than for any unit; if it never appears, leave it to
      # the next timer tick instead of failing.
      for _ in $(seq 30); do
        busctl --user --quiet status org.freedesktop.Notifications >/dev/null 2>&1 && break
        sleep 2
      done
      if ! busctl --user --quiet status org.freedesktop.Notifications >/dev/null 2>&1; then
        echo "no notification daemon on the session bus after 60 s; will retry on the next check"
        exit 0
      fi

      # Sent through org.freedesktop.Notifications, so whichever daemon the
      # session runs shows it. Persistence uses spec-level means only: a 0 ms
      # expiry (never expire), critical urgency, and the resident hint (stay
      # after an action). Each run replaces the previous notification by id
      # rather than stacking a second copy.
      idFile="''${XDG_RUNTIME_DIR:-/tmp}/org-home-drift.id"
      replaceId="$(cat "$idFile" 2>/dev/null || echo 0)"

      notify-send \
        --app-name="Organisation Security" \
        --urgency=critical \
        --expire-time=0 \
        --hint=boolean:resident:true \
        --icon=dialog-error \
        --replace-id="$replaceId" \
        --print-id \
        "⛔ NON-COMPLIANT: your home has drifted from the organisation configuration" \
        "Your environment is running configuration ''${actual:0:12} but this machine requires ''${expected:0:12}. Until you fix it, you are on settings and security policy the organisation no longer approves, and this machine is recorded as non-compliant.

Fix it right now — open a terminal and run:

    home-manager switch --flake /etc/nixos --impure

This warning will return every 30 minutes, after every system update and at every login until you do." > "$idFile"
    '';
  };
in {
  config = lib.mkMerge [
    { environment.etc."org/revision".text = revision; }

    (lib.mkIf (selfManaged != [ ] && config.conf.desktop.enable) {
      systemd.user.services.org-home-drift = {
        description = "Check this user's self-managed home against the organisation configuration";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe check;
        };
      };

      # Re-check while the session lasts, so a dismissed warning comes back. A
      # compliant run exits at once, so the timer costs nothing once the home is
      # current. The first tick is 30 minutes in, since the service already ran
      # at login.
      systemd.user.timers.org-home-drift = {
        description = "Re-check this user's self-managed home every 30 minutes";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        timerConfig = {
          OnActiveSec = "30min";
          OnUnitActiveSec = "30min";
        };
      };

      # switch-to-configuration restarts nixos-activation in every logged-in
      # user's manager, which runs this as that user. wantedBy only takes
      # effect when graphical-session.target next starts, i.e. at the next
      # login, so a session that was already running when the switch added or
      # changed these units would get neither the timer nor the check. Start
      # both here, but only in a graphical session: an SSH-only session has no
      # notification daemon to show anything. --no-block so a slow daemon
      # cannot hold up activation.
      system.userActivationScripts.orgHomeDrift = ''
        if ${pkgs.systemd}/bin/systemctl --user is-active --quiet graphical-session.target; then
          ${pkgs.systemd}/bin/systemctl --user start --no-block org-home-drift.timer org-home-drift.service || true
        fi
      '';
    })
  ];
}
