{ pkgs, lib, config, ... }:
let
  dev = config.conf.development;

  getPackages = group: defaultPkgs:
  (if group.packages != [] then group.packages else defaultPkgs) ++ group.extraPackages;

  defaultBasePackages = with pkgs; [
    gh
    tree-sitter
    nodejs
    clang
    tmux
    fzf
  ];

  defaultCppPackages = with pkgs; [
    clang
    clang-tools
    cmake
  ];

  defaultGoPackages = with pkgs; [
    go
    gopls
  ];

  defaultRustPackages = with pkgs; [
    rustup
  ];

  defaultPythonPackages = with pkgs; [
    python3
  ];

  defaultJavaPackages = with pkgs; [
    zulu
  ];

  defaultNixPackages = with pkgs; [
    nil
  ];

  defaultLuaPackages = with pkgs; [
    lua
    lua-language-server
  ];

  defaultCuePackages = with pkgs; [
    cue
    cuelsp
  ];

  sdkPackages =
    lib.optionals dev.sdk.base.enable (getPackages dev.sdk.base (defaultBasePackages))
    ++ lib.optionals dev.sdk.cpp.enable (getPackages dev.sdk.cpp (defaultCppPackages))
    ++ lib.optionals dev.sdk.go.enable (getPackages dev.sdk.go (defaultGoPackages))
    ++ lib.optionals dev.sdk.rust.enable (getPackages dev.sdk.rust (defaultRustPackages))
    ++ lib.optionals dev.sdk.python.enable (getPackages dev.sdk.python (defaultPythonPackages))
    ++ lib.optionals dev.sdk.java.enable (getPackages dev.sdk.java (defaultJavaPackages))
    ++ lib.optionals dev.sdk.nix.enable (getPackages dev.sdk.nix (defaultNixPackages))
    ++ lib.optionals dev.sdk.nix.enable (getPackages dev.sdk.cue (defaultCuePackages))
    ++ lib.optionals dev.sdk.lua.enable (getPackages dev.sdk.lua (defaultLuaPackages));
in {
  environment.systemPackages = lib.optionals dev.enable sdkPackages;
}
