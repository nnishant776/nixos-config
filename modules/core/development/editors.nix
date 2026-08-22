{ pkgs, lib, config, ... }:
let
  dev = config.myconf.development;

  getPackages = group: defaultPkgs:
    (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  editorPackages =
    lib.optionals dev.editors.vscode.enable (getPackages dev.editors.vscode [ ])
    ++ lib.optionals dev.editors.neovim.enable (getPackages dev.editors.neovim (with pkgs; [ neovim ]))
    ++ lib.optionals dev.editors.emacs.enable (getPackages dev.editors.emacs (with pkgs; [ emacs libtool ]));
in {
  config.environment.systemPackages = lib.optionals dev.enable editorPackages;
}
