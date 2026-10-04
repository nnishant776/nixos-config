{ lib, ... }:
let
  packageList = desc: lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = desc;
  };

  # Every group shares the same shape: `packages` replaces the curated default
  # set, `extraPackages` appends to whichever set results. Editors add two
  # fields for where their configuration comes from.
  mkPackageGroup = desc: extraFields: {
    enable = lib.mkEnableOption desc;
    packages = packageList "Replaces the curated default set for ${desc}.";
    extraPackages = packageList "Appended to whichever set `packages` resolves to, for ${desc}.";
    nix-ldLibraries = packageList "Runtime shared libraries exported to nix-ld for ${desc}.";
  } // extraFields;

  mkSdkGroup = desc: mkPackageGroup desc { };
  mkToolGroup = desc: mkPackageGroup desc { };
  mkEditorGroup = desc: mkPackageGroup desc {
    configPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Local path for ${desc} configuration.";
    };
    configRepo = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Remote repository for ${desc} configuration.";
    };
  };
in {
  options.conf.development = {
    enable = lib.mkEnableOption "the development tooling stack";
    extraPackages = packageList "Extra top-level development packages.";

    sdk = {
      base   = mkSdkGroup "the base SDK (gh, tmux, nodejs, clang)";
      cpp    = mkSdkGroup "the C/C++ SDK (clang-tools, cmake)";
      go     = mkSdkGroup "the Go SDK";
      rust   = mkSdkGroup "the Rust SDK (rustup)";
      python = mkSdkGroup "the Python SDK (python3)";
      java   = mkSdkGroup "the Java SDK (Zulu JDK)";
      nix    = mkSdkGroup "Nix tooling (nil LSP)";
      cue    = mkSdkGroup "CUE tooling";
      lua    = mkSdkGroup "the Lua SDK (lua, lua-language-server)";
    };

    editors = {
      neovim = mkEditorGroup "Neovim";
      emacs  = mkEditorGroup "Emacs";
      vscode = mkEditorGroup "VS Code";
    };

    tools = {
      gemini   = mkToolGroup "the Gemini / Antigravity CLI";
      opencode = mkToolGroup "the OpenCode CLI";
      rtk      = mkToolGroup "the RTK CLI";
    };

    nixLd = {
      enable = lib.mkEnableOption "exporting the curated library set to nix-ld, for running downloaded binaries";
      libraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Replaces the curated default set in
          modules/linux/development/ld-libraries.nix. Leave it empty to keep that
          set and use `extraLibraries` to add to it.
        '';
      };
      extraLibraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Appended to whichever set `libraries` resolves to. The SDK, editor,
          tool, graphics, multimedia and virtualisation groups contribute their
          own `nix-ldLibraries` on top of this.
        '';
      };
    };
  };
}
