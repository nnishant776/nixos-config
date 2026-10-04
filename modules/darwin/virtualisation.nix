{ config, lib, pkgs, ... }:
let
  cfg = config.conf.virtualisation;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      colima
      lima
      lima-additional-guestagents
    ] ++ cfg.extraPackages;

    # Rosetta 2, so x86_64 container images and binaries run on Apple silicon.
    # nix-darwin only executes its fixed set of activation scripts, so this
    # hooks into postActivation rather than declaring a script of its own, and
    # it checks the installed receipt first so the network call happens once.
    system.activationScripts.postActivation.text = lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 ''
      if ! /usr/bin/pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
        echo "Installing Rosetta 2"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license || true
      fi
    '';
  };
}
