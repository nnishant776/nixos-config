{ lib, ... }: {
  options.conf.platform = lib.mkOption {
    type = lib.types.enum [ "nixos" "darwin" "system-manager" ];
    readOnly = true;
    description = ''
      Which kind of system this configuration is deployed to. Set by
      `lib/mkHost.nix`; hosts do not set it, and a host that tries fails
      evaluation.

      Use it for differences that belong to the deployment rather than the
      platform, such as whether nix is part of the system closure, and use
      `pkgs.stdenv.hostPlatform.isLinux`/`isDarwin` for the rest.
    '';
  };
}
