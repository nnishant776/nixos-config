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

      serviceConfig = {
        Type = "oneshot";
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
