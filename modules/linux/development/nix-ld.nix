{ pkgs, lib, config, ... }:
let
  ldCfg = config.conf.development.nixLd;
  dev = config.conf.development;

  # Kept here rather than as the option default so that the list, which holds
  # Linux-only packages, is never forced on Darwin.
  defaultLdLibraries = import ./ld-libraries.nix { inherit pkgs; };

  hostLibraries =
    (if ldCfg.libraries != [ ] then ldCfg.libraries else defaultLdLibraries)
    ++ ldCfg.extraLibraries;

  groupLibraries =
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
  ;
in {
  # Enable nix-ld for precompiled dynamic binary execution
  config.programs.nix-ld.enable = true;

  # Host-wide default libraries, plus development runtime libraries exported
  # via nix-ld (Linux only)
  config.programs.nix-ld.libraries = lib.mkMerge [
    (lib.mkIf ldCfg.enable hostLibraries)
    (lib.mkIf (config.programs.nix-ld.enable or false && dev.enable) groupLibraries)
  ];
}
