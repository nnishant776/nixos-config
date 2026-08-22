{ inputs, pkgs, lib, config, ... }:
let
  dev = config.myconf.development;

  base_sdk_packages = with pkgs; [
    gh
    tree-sitter
    nodejs
    tmux
  ];

  getPackages = group: defaultPkgs:
    (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  installedDevPackages = with pkgs; [
    uv
  ]
  ++ dev.extraPackages
  ++ lib.optionals dev.sdk.base.enable (getPackages dev.sdk.base base_sdk_packages)
  ++ lib.optionals dev.sdk.cpp.enable (getPackages dev.sdk.cpp (with pkgs; [ cmake ]))
  ++ lib.optionals dev.sdk.go.enable (getPackages dev.sdk.go (with pkgs; [ go ]))
  ++ lib.optionals dev.sdk.rust.enable (getPackages dev.sdk.rust (with pkgs; [ rustup ]))
  ++ lib.optionals dev.sdk.python.enable (getPackages dev.sdk.python (with pkgs; [ python3 ]))
  ++ lib.optionals dev.sdk.java.enable (getPackages dev.sdk.java (with pkgs; [ zulu ]))
  ++ lib.optionals dev.sdk.nix.enable (getPackages dev.sdk.nix (with pkgs; [ nil ]))
  ++ lib.optionals dev.sdk.lua.enable (getPackages dev.sdk.lua (with pkgs; [ lua lua-language-server ]))

  ++ lib.optionals dev.editors.vscode.enable (getPackages dev.editors.vscode [ ])
  ++ lib.optionals dev.editors.neovim.enable (getPackages dev.editors.neovim (with pkgs; [ neovim ]))
  ++ lib.optionals dev.editors.emacs.enable (getPackages dev.editors.emacs (with pkgs; [ emacs ]))

  ++ lib.optionals dev.tools.gemini.enable (getPackages dev.tools.gemini (with pkgs; [ nodejs_22 bun ]))
  ++ lib.optionals dev.tools.rtk.enable (getPackages dev.tools.rtk (with pkgs; [ rtk ]));

in {
  environment.systemPackages = lib.optionals dev.enable installedDevPackages;
}
