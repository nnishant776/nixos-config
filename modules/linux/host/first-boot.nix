{ ... }:
{
  config = {
    systemd.services.run-once-on-first-boot = {
      description = "Run script exactly once on first boot";

      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig = {
        ConditionPathExists = "!/var/lib/run-once-on-first-boot.done";
      };

      # Writes a marker under /root and /var/lib on first boot; nothing to
      # sandbox beyond a private /tmp.
      serviceConfig = {
        Type = "oneshot";
        PrivateTmp = true;
        RemainAfterExit = true;
      };

      script = ''
        echo "Executing first-boot initialization tasks..."

        touch /root/.disko-partitioning.done
        touch /var/lib/run-once-on-first-boot.done
      '';
    };
  };
}
