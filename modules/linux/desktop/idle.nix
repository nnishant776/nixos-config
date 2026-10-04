# Lock on idle and before sleep, for sessions whose compositor has nothing
# managing it: Hyprland with shell = none, and Sway. DMS, Noctalia and
# Caelestia carry their own idle handling, and two lockers stack, so they are
# left alone. A system-level user unit belongs to the organisation and does
# not touch the user's Home Manager generation.
{ config, lib, pkgs, ... }:
let
  cfg = config.conf.desktop;
  bareHyprland = cfg.environments.hyprland.enable && cfg.environments.hyprland.shell == "none";
  wanted = cfg.enable && cfg.idleLockSeconds > 0 && (bareHyprland || cfg.environments.sway.enable);

  # The locker for whichever compositor is running.
  locker = pkgs.writeShellScript "org-lock" ''
    case "''${XDG_CURRENT_DESKTOP:-}" in
      ${lib.optionalString bareHyprland ''*Hyprland*) exec ${pkgs.hyprlock}/bin/hyprlock ;;''}
      *) exec ${pkgs.swaylock}/bin/swaylock -f ;;
    esac
  '';
in {
  config = lib.mkIf wanted {
    systemd.user.services.org-idle-lock = {
      description = "Lock the session when idle and before sleep";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout ${toString cfg.idleLockSeconds} ${locker} before-sleep ${locker} lock ${locker}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
