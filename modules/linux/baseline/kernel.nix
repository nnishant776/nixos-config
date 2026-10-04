# Kernel posture every Linux host gets. All mkDefault, so a host overrides any
# line with a plain value. Keys NixOS already defines with mkDefault use
# mkOverride 900 instead, which still loses to a host's plain definition.
{ config, lib, ... }:
let
  headless = builtins.elem config.conf.machineType [ "headless" "vm" ];
in {
  config = {
    boot.kernel.sysctl = {
      "kernel.dmesg_restrict" = lib.mkDefault 1;
      "kernel.kptr_restrict" = lib.mkOverride 900 2;
      # Debuggers attach to their own children only; attaching to an arbitrary
      # process of the same user needs CAP_SYS_PTRACE (sudo).
      "kernel.yama.ptrace_scope" = lib.mkDefault 1;
      "kernel.unprivileged_bpf_disabled" = lib.mkDefault 1;
      "net.core.bpf_jit_harden" = lib.mkDefault 2;
      "kernel.sysrq" = lib.mkDefault 4;
      "fs.suid_dumpable" = lib.mkDefault 0;
      "fs.protected_fifos" = lib.mkDefault 2;
      "fs.protected_regular" = lib.mkDefault 2;
      "vm.unprivileged_userfaultfd" = lib.mkDefault 0;

      "net.ipv4.tcp_syncookies" = lib.mkDefault 1;
      "net.ipv4.tcp_rfc1337" = lib.mkDefault 1;
      "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.all.secure_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.default.secure_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.default.send_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.all.accept_source_route" = lib.mkDefault 0;
      "net.ipv4.conf.default.accept_source_route" = lib.mkDefault 0;
      "net.ipv4.conf.all.log_martians" = lib.mkDefault 1;
      "net.ipv4.conf.default.log_martians" = lib.mkDefault 1;
      "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
      "net.ipv6.conf.default.accept_redirects" = lib.mkDefault 0;
      "net.ipv6.conf.all.accept_source_route" = lib.mkDefault 0;
    };

    # Network protocols nothing here uses, with a history of remotely reachable bugs.
    boot.blacklistedKernelModules = [ "dccp" "sctp" "rds" "tipc" ];

    # Crashes are still logged, but no process memory is written to disk.
    systemd.coredump.settings.Coredump = {
      Storage = lib.mkDefault "none";
      ProcessSizeMax = lib.mkDefault 0;
    };

    boot.tmp.cleanOnBoot = lib.mkDefault true;

    # Disables kexec and hibernation; interactive machines keep hibernation.
    security.protectKernelImage = lib.mkDefault headless;
  };
}
