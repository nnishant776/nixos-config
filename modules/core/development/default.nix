{ pkgs, lib, config, ... }:
let
  dev = config.conf.development;
in {
  imports = [
    ./sdk.nix
    ./editors.nix
    ./tools.nix
  ];

  config.environment.systemPackages = lib.optionals dev.enable (
    with pkgs; [
      uv
    ]
    ++ dev.extraPackages
  );
}
