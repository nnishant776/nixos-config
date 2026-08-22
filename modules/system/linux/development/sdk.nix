{ pkgs, lib, config, ... }:
let
  dev = config.myconf.development;

  getPackages = group: defaultPkgs:
    (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  sdkPackages =
    lib.optionals dev.sdk.base.enable (getPackages dev.sdk.base (with pkgs; [ gh tree-sitter nodejs clang tmux ]))
    ++ lib.optionals dev.sdk.cpp.enable (getPackages dev.sdk.cpp (with pkgs; [ clang-tools cmake ]))
    ++ lib.optionals dev.sdk.go.enable (getPackages dev.sdk.go (with pkgs; [ go ]))
    ++ lib.optionals dev.sdk.rust.enable (getPackages dev.sdk.rust (with pkgs; [ rustup ]))
    ++ lib.optionals dev.sdk.python.enable (getPackages dev.sdk.python (with pkgs; [ python3 ]))
    ++ lib.optionals dev.sdk.java.enable (getPackages dev.sdk.java (with pkgs; [ zulu ]))
    ++ lib.optionals dev.sdk.nix.enable (getPackages dev.sdk.nix (with pkgs; [ nil ]))
    ++ lib.optionals dev.sdk.lua.enable (getPackages dev.sdk.lua (with pkgs; [ lua lua-language-server ]));
in {
  config = {
    environment.systemPackages = lib.optionals dev.enable sdkPackages;

    programs.nix-ld.libraries = lib.mkIf (config.programs.nix-ld.enable or false && dev.enable) (
      lib.optionals dev.sdk.base.enable dev.sdk.base.nix-ldLibraries
      ++ lib.optionals dev.sdk.cpp.enable (dev.sdk.cpp.nix-ldLibraries ++ [ pkgs.stdenv.cc.cc.lib pkgs.llvmPackages.libcxx or pkgs.stdenv.cc.cc.lib ])
      ++ lib.optionals dev.sdk.go.enable dev.sdk.go.nix-ldLibraries
      ++ lib.optionals dev.sdk.rust.enable dev.sdk.rust.nix-ldLibraries
      ++ lib.optionals dev.sdk.python.enable (dev.sdk.python.nix-ldLibraries ++ [ pkgs.python3 ])
      ++ lib.optionals dev.sdk.java.enable dev.sdk.java.nix-ldLibraries
      ++ lib.optionals dev.sdk.nix.enable dev.sdk.nix.nix-ldLibraries
      ++ lib.optionals dev.sdk.lua.enable dev.sdk.lua.nix-ldLibraries
    );
  };
}
