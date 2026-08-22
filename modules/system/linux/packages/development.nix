{ inputs, pkgs, lib, config, ... }:
let
  dev = config.myconf.development;

  getPackages = group: defaultPkgs:
    (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  installedDevPackages = with pkgs; [
    uv
  ]
  ++ dev.extraPackages
  ++ lib.optionals dev.sdk.base.enable (getPackages dev.sdk.base (with pkgs; [gh tree-sitter nodejs clang tmux]))
  ++ lib.optionals dev.sdk.cpp.enable (getPackages dev.sdk.cpp (with pkgs; [ clang-tools cmake ]))
  ++ lib.optionals dev.sdk.go.enable (getPackages dev.sdk.go (with pkgs; [ go ]))
  ++ lib.optionals dev.sdk.rust.enable (getPackages dev.sdk.rust (with pkgs; [ rustup ]))
  ++ lib.optionals dev.sdk.python.enable (getPackages dev.sdk.python (with pkgs; [ python3 ]))
  ++ lib.optionals dev.sdk.java.enable (getPackages dev.sdk.java (with pkgs; [ zulu ]))
  ++ lib.optionals dev.sdk.nix.enable (getPackages dev.sdk.nix (with pkgs; [ nil ]))
  ++ lib.optionals dev.sdk.lua.enable (getPackages dev.sdk.lua (with pkgs; [ lua lua-language-server ]))

  ++ lib.optionals dev.editors.vscode.enable (getPackages dev.editors.vscode [ ])
  ++ lib.optionals dev.editors.neovim.enable (getPackages dev.editors.neovim (with pkgs; [ neovim ]))
  ++ lib.optionals dev.editors.emacs.enable (getPackages dev.editors.emacs (with pkgs; [ emacs libtool ]))

  ++ lib.optionals dev.tools.gemini.enable (getPackages dev.tools.gemini (with pkgs; [ nodejs_22 bun antigravity ]))
  ++ lib.optionals dev.tools.opencode.enable (getPackages dev.tools.opencode (with pkgs; [ opencode ]))
  ++ lib.optionals dev.tools.rtk.enable (getPackages dev.tools.rtk (with pkgs; [ rtk ]));

in {
  config = {
    environment.systemPackages = lib.optionals dev.enable installedDevPackages;

    # Automatically aggregate development runtime libraries into nix-ld
    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false && dev.enable) (
      dev.extraPackages
      ++ lib.optionals dev.sdk.base.enable dev.sdk.base.nix-ldLibraries
      ++ lib.optionals dev.sdk.cpp.enable (dev.sdk.cpp.nix-ldLibraries ++ [ pkgs.stdenv.cc.cc.lib pkgs.llvmPackages.libcxx or pkgs.stdenv.cc.cc.lib ])
      ++ lib.optionals dev.sdk.go.enable dev.sdk.go.nix-ldLibraries
      ++ lib.optionals dev.sdk.rust.enable dev.sdk.rust.nix-ldLibraries
      ++ lib.optionals dev.sdk.python.enable (dev.sdk.python.nix-ldLibraries ++ [ pkgs.python3 ])
      ++ lib.optionals dev.sdk.java.enable dev.sdk.java.nix-ldLibraries
      ++ lib.optionals dev.sdk.nix.enable dev.sdk.nix.nix-ldLibraries
      ++ lib.optionals dev.sdk.lua.enable dev.sdk.lua.nix-ldLibraries
      ++ lib.optionals dev.editors.vscode.enable dev.editors.vscode.nix-ldLibraries
      ++ lib.optionals dev.editors.neovim.enable dev.editors.neovim.nix-ldLibraries
      ++ lib.optionals dev.editors.emacs.enable (dev.editors.emacs.nix-ldLibraries ++ [ pkgs.libtool ])
      ++ lib.optionals dev.tools.gemini.enable (dev.tools.gemini.nix-ldLibraries ++ [
        pkgs.glib
        pkgs.ffmpeg
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-ugly
        pkgs.pipewire
        pkgs.wireplumber
        pkgs.alsa-lib
      ])
      ++ lib.optionals dev.tools.rtk.enable dev.tools.rtk.nix-ldLibraries
    );
  };
}
