{ pkgs, lib, config, ... }:
let
  dev = config.myconf.development;

  getPackages = group: defaultPkgs:
    (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  toolPackages =
    lib.optionals dev.tools.gemini.enable (getPackages dev.tools.gemini (with pkgs; [ nodejs_22 bun antigravity ]))
    ++ lib.optionals dev.tools.opencode.enable (getPackages dev.tools.opencode (with pkgs; [ opencode ]))
    ++ lib.optionals dev.tools.rtk.enable (getPackages dev.tools.rtk (with pkgs; [ rtk ]));
in {
  config.environment.systemPackages = lib.optionals dev.enable toolPackages;
}
