# Hand the screen from Plymouth to the greeter without a gap. By default
# Plymouth quits at multi-user.target and greetd starts after it, so for the
# second it takes cage and ReGreet to draw, tty1 shows through (boot text,
# blank frames). This is the arrangement GDM uses: Plymouth is not quit on its
# own; greetd quits it with --retain-splash as it starts, so the last splash
# frame stays on screen until the greeter replaces it.
{ config, lib, ... }:
let
  plymouth = config.boot.plymouth;
in {
  config = lib.mkIf (config.conf.desktop.enable && plymouth.enable) {
    # Tells the greetd module not to order greetd after plymouth-quit-wait.
    services.greetd.greeterManagesPlymouth = true;

    systemd.services.greetd = {
      after = [ "plymouth-start.service" ];
      # Running greetd stops plymouth-quit from being started at all, and a
      # failed greeter falls back to quitting Plymouth so the console is
      # usable.
      conflicts = [ "plymouth-quit.service" ];
      onFailure = [ "plymouth-quit.service" ];
      # As root, before greetd: release the display but leave the splash
      # image up. '-': no Plymouth running (a later restart of greetd) is fine.
      serviceConfig.ExecStartPre = [ "-${plymouth.package}/bin/plymouth quit --retain-splash" ];
      # greetd is Type=idle upstream, which waits up to 5 s for other boot
      # jobs to finish. plymouth-quit-wait only finishes once Plymouth exits,
      # which is now greetd's doing, so idle would always cost the full 5 s.
      # idle exists to keep console output away from a text greeter; here the
      # retained splash covers the screen until cage draws.
      serviceConfig.Type = lib.mkForce "simple";
    };

    # Without this, a rebuild that starts multi-user.target would start
    # plymouth-quit, which conflicts with greetd and would stop the greeter.
    systemd.services.plymouth-quit.wantedBy = lib.mkForce [ ];
  };
}
