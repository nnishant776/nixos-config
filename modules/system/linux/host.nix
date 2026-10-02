{ config, pkgs, lib, flakeLib, ... }:
let
  users = config.conf.host.users;
  svc = config.conf.systemServices;

  # Groups that confer root or near-root. These must follow from a user's
  # `privileged` flag — never from a hand-written group list, and never from a
  # service merely being enabled, which is how this configuration previously
  # handed every user on a `developer` profile host root-equivalent access:
  #
  #   wheel           sudo.
  #   docker          root. `docker run -v /:/host --privileged` and the machine
  #                   is yours — no sudo entry, nothing in sudoers to audit.
  #   podman          the rootful podman socket, same reasoning as docker.
  #   libvirtd        define a VM with host disk passthrough, i.e. read any file
  #                   on the host as root. This is the group to withhold; see
  #                   the note below on how unprivileged users still run VMs.
  #   networkmanager  NixOS gives this group a blanket polkit YES for every
  #                   org.freedesktop.NetworkManager.* action (a prefix match,
  #                   not an allowlist), which covers rewriting system-wide
  #                   connections, global DNS and the hostname, and opening a
  #                   Wi-Fi hotspot.
  privilegedGroups = [ "wheel" "docker" "podman" "libvirtd" "networkmanager" ];

  # Deliberately NOT in the list above: `kvm`.
  #
  # systemd's own udev rule ships /dev/kvm as world-accessible —
  #   KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"
  # — because KVM is designed to be safe to expose to unprivileged users. The
  # group is empty on a stock NixOS system and grants nothing, so treating it as
  # privilege would misrepresent the model: withholding it denies no capability.
  #
  # It is still granted below, to every user rather than only privileged ones,
  # purely as insurance: if upstream ever tightens that mode back to 0660, group
  # membership is what keeps VMs working.
  #
  # So an unprivileged user runs VMs via libvirt *session* mode
  # (qemu:///session, which virt-manager speaks), plain qemu, or
  # `nixos-rebuild build-vm` — all with KVM acceleration and none needing a
  # group. What they give up is system-mode libvirt: bridged networking, PCI/USB
  # passthrough, VMs that start at boot, and host-level storage pools. "I need
  # to run a VM" is therefore not a reason to grant `libvirtd`.

  # What a non-privileged user needs in order to join and switch networks.
  # Deliberately omitted: settings.modify.system, settings.modify.global-dns,
  # settings.modify.hostname, wifi.share.open, wifi.share.protected,
  # checkpoint-rollback and reload — none has a legitimate non-admin use.
  #
  # Note this still permits settings.modify.own, and a connection a user owns
  # can carry its own ipv4.dns. Pinning the resolver is a network-layer job
  # (networkmanager.dns + firewall), not something polkit can do.
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
    # Set hostname
    networking.hostName = config.conf.host.name;

    # Add registered users
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
    # Registration order relative to those rules does not matter: polkit takes
    # the first non-undefined result, and the two match disjoint groups.
    #
    # Note NixOS adds a second blanket rule for org.freedesktop.ModemManager,
    # also keyed on the networkmanager group. Nothing is allowlisted here for it,
    # so a non-privileged user can toggle WWAN through NetworkManager but cannot
    # drive the modem directly (SIM unlock and the like). Revisit if the fleet
    # uses built-in cellular.
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

    # Set timezone
    time.timeZone = config.conf.host.timezone;

    # Set up first boot tasks
    systemd.services.run-once-on-first-boot = {
      description = "Run script exactly once on first boot";

      # Ensure it runs late enough if you need networking or full system initialized
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];

      # This condition prevents the service from running if the file already exists
      unitConfig = {
        ConditionPathExists = "!/var/lib/run-once-on-first-boot.done";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        echo "Executing first-boot initialization tasks..."

        # Commands to run on first boot
        touch /root/.disko-partitioning.done

        # Create the token file so this service is skipped on subsequent boots
        touch /var/lib/run-once-on-first-boot.done
      '';
    };
  };
}
