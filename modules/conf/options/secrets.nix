{ lib, ... }: {
  options.conf.secrets.file = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    example = lib.literalExpression "./secrets.yaml";
    description = ''
      sops-encrypted file holding this host's secrets, committed to the
      repository. The machine decrypts it with the age key sops-nix keeps at
      `/var/lib/sops-nix/key.txt`, generated on first activation; its public
      half is what goes into `.sops.yaml`. `null` means the host has no
      secrets and the sops machinery stays off.
    '';
  };
}
