{ config, pkgs, lib, flakeLib, ... }:
let
  users = config.conf.host.users;
  svc = config.conf.systemServices;

  # Groups that confer root or near-root (wheel: sudo; docker/podman: rootful
  # sockets; libvirtd: VM disk passthrough; networkmanager: a blanket polkit
  # YES for every org.freedesktop.NetworkManager.* action). These must follow
  # from a user's `privileged` flag — never from a hand-written group list,
  # and never from a service merely being enabled.
  privilegedGroups = [ "wheel" "docker" "podman" "libvirtd" "networkmanager" ];

  # Deliberately NOT in the list above: `kvm`. /dev/kvm is world-accessible by
  # default udev rule, so the group grants nothing and is given to every user,
  # not just privileged ones, as insurance against that mode ever tightening.
  # An unprivileged user still runs VMs via libvirt session mode, plain qemu,
  # or `nixos-rebuild build-vm`; what they lose without `libvirtd` is
  # system-mode libvirt (bridged networking, PCI/USB passthrough, boot-time
  # VMs, host storage pools).

  # What a non-privileged user needs in order to join and switch networks.
  # Deliberately omitted: settings.modify.system, settings.modify.global-dns,
  # settings.modify.hostname, wifi.share.open, wifi.share.protected,
  # checkpoint-rollback and reload — none has a legitimate non-admin use. This
  # still permits settings.modify.own, so a connection a user owns can carry
  # its own ipv4.dns; pinning the resolver is a network-layer job, not a
  # polkit one.
  networkUserActions = [
    "org.freedesktop.NetworkManager.enable-disable-network"
    "org.freedesktop.NetworkManager.enable-disable-wifi"
    "org.freedesktop.NetworkManager.enable-disable-wwan"
    "org.freedesktop.NetworkManager.network-control"
    "org.freedesktop.NetworkManager.wifi.scan"
    "org.freedesktop.NetworkManager.settings.modify.own"
    "org.freedesktop.NetworkManager.sleep-wake"
    "org.freedesktop.NetworkManager.enable-disable-statistics"
    "org.freedesktop.NetworkManager.enable-disable-connectivity-check"
  ];

  groupsFor = user:
    user.groups
    # Seat access for a graphical session: not privilege-relevant.
    ++ lib.optionals config.conf.desktop.enable [ "video" "input" ]
    # Not a privilege — see the note on kvm above.
    ++ lib.optionals svc.virtualisation.enable [ "kvm" ]
    ++ lib.optionals user.privileged (
      [ "wheel" ]
      ++ lib.optionals svc.networking.enable [ "networkmanager" ]
      ++ lib.optionals svc.containerisation.enable [ "docker" "podman" ]
      ++ lib.optionals svc.virtualisation.enable [ "libvirtd" ]
    )
    ++ lib.optionals (!user.privileged && svc.networking.enable) [ "network-users" ];

  offendingGroups = user: lib.intersectLists user.groups privilegedGroups;

  # manageAccount exists for Darwin, where accounts come from MDM. On Linux it
  # must stay true — asserted below rather than half-supported.
  accountManaged = flakeLib.accountManaged config.conf.platform;
in
{
  config = {
    networking.hostName = config.conf.host.name;

    users.users = lib.mapAttrs (username: user: {
      isNormalUser = true;
      description = user.fullName;
      extraGroups = lib.unique (groupsFor user);
      initialHashedPassword = user.initialHashedPassword;
    }) users;

    # Holds the narrow NetworkManager permissions below.
    users.groups = lib.mkIf svc.networking.enable { network-users = { }; };

    # sudo is reachable only through wheel, which only `privileged` grants.
    security.sudo.execWheelOnly = true;

    # Non-privileged users are not in `networkmanager`, so NixOS' blanket rules
    # for that group never match them and this allowlist is what they get.
    # NixOS also has a blanket rule for org.freedesktop.ModemManager keyed on
    # the same group; nothing is allowlisted here for it, so a non-privileged
    # user can toggle WWAN but cannot drive the modem directly.
    security.polkit.extraConfig = lib.mkIf svc.networking.enable ''
      polkit.addRule(function(action, subject) {
        var allowed = [${lib.concatMapStringsSep "" (a: "\n    \"${a}\",") networkUserActions}
        ];
        if (subject.isInGroup("network-users") && allowed.indexOf(action.id) !== -1) {
          return polkit.Result.YES;
        }
      });
    '';

    assertions =
      # `groups` is for non-privilege extras only, so that sudo-equivalent
      # access is declared in exactly one place and can be checked.
      (lib.mapAttrsToList (username: user: {
        assertion = offendingGroups user == [ ];
        message =
          "conf.host.users.${username} lists privilege-granting group(s) "
          + lib.concatStringsSep ", " (offendingGroups user)
          + " in `groups`. Set `privileged = true` instead — those groups are"
          + " derived from that flag.";
      }) users)
      ++
      # Defence in depth: check the merged result, so a grant arriving from any
      # other module is caught too. Only for accounts declared here — there is
      # no users.users entry to inspect for the others.
      (lib.mapAttrsToList (username: user: {
        assertion =
          user.privileged
          || lib.intersectLists config.users.users.${username}.extraGroups privilegedGroups == [ ];
        message =
          "conf.host.users.${username} is not privileged but ended up in "
          + lib.concatStringsSep ", "
            (lib.intersectLists config.users.users.${username}.extraGroups privilegedGroups)
          + ", which confers root or near-root. Something outside conf.host"
          + " granted it.";
      }) users)
      ++
      (lib.mapAttrsToList (username: user: {
        assertion = accountManaged user;
        message =
          "conf.host.users.${username} has manageAccount = false, which is not"
          + " supported on Linux. Home-Manager's NixOS integration reads"
          + " users.users.${username}.name and .home unconditionally, so it needs"
          + " an account this configuration declares; and granting groups to an"
          + " account declared elsewhere would mean managing local groups that a"
          + " directory service may also own, with the GID collisions that"
          + " implies. The flag exists for Darwin, where accounts come from MDM.";
      }) users);

    # Not an assertion: a kiosk or an appliance managed entirely by the sync
    # timer legitimately has nobody who can sudo. On a workstation it is a
    # lockout, so it is worth saying out loud.
    warnings = lib.optional (!(lib.any (u: u.privileged) (lib.attrValues users)))
      ("conf.host.users on '${config.conf.host.name}' declares no privileged user,"
        + " so no account on this machine can use sudo. Intentional for an"
        + " appliance; a lockout for anything interactive.");

    time.timeZone = config.conf.host.timezone;

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
