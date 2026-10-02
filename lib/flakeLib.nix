# Helpers shared by this flake's own modules.
#
# Threaded to every module as `flakeLib` via specialArgs / extraSpecialArgs by
# lib/mkHost.nix and lib/mkUser.nix.
{ lib }:
rec {
  # Does this configuration own the account itself, as opposed to only its home?
  #
  # conf.host.users.<name>.manageAccount is nullOr bool: null resolves by
  # platform, because accounts come from different places — a NixOS machine
  # declares them, a Mac gets them from MDM. An explicit value wins.
  #
  # Defined here so the NixOS and Darwin modules cannot drift apart on it.
  accountManaged = platform: user:
    if user.manageAccount != null
    then user.manageAccount
    else platform != "darwin";

  # Recursively mark a module's option definitions as lib.mkDefault, so a host
  # (or a per-user module) can override them with a plain assignment instead of
  # colliding with them.
  #
  #   config = flakeLib.mkDefaults {
  #     time.timeZone = "Asia/Kolkata";
  #     services.openssh.settings.PermitRootLogin = "no";
  #   };
  #
  # Opt in per module, deliberately. Three things it will NOT do, because doing
  # them automatically is how you get silent breakage:
  #
  #   * Lists are left untouched. List definitions concatenate, so defaulting one
  #     would mean any other definition REPLACES it outright rather than adding to
  #     it. modules/system/linux/desktop/fonts.nix and
  #     modules/core/development/fonts.nix both contribute to fonts.packages;
  #     defaulting either would silently drop the other's packages. If you do want
  #     replace-semantics, write `lib.mkDefault [ ... ]` yourself.
  #
  #   * Anything already carrying a priority (lib.mkDefault, lib.mkForce,
  #     lib.mkOverride) is left exactly as written, so a deliberate mkForce inside
  #     a defaulted module still means mkForce.
  #
  #   * Opaque values are not descended into: derivations, store paths, functions,
  #     and anything you wrap yourself. This matters for freeform options whose
  #     value is plain data (types.attrs / types.anything, e.g. a settings blob) —
  #     descending into those would embed override markers INSIDE your data and
  #     corrupt it. Wrap those at the option boundary instead:
  #     `settings = lib.mkDefault { ... };`
  #
  # lib.mkIf / lib.mkMerge are transparent: their payloads are walked, so both
  # `config = lib.mkIf c (mkDefaults { ... })` and `mkDefaults { x = lib.mkIf c { ... }; }`
  # behave the way you would expect.
  mkDefaults =
    let
      # A value to define, rather than a tree of further definitions.
      isLeaf = v:
        !(builtins.isAttrs v)
        || lib.isDerivation v
        || v ? outPath
        || v ? __functor;

      walk = v:
        if builtins.isList v then v
        else if isLeaf v then lib.mkDefault v
        else if v ? _type then
          # Look through the module system's own wrappers, but never re-prioritise
          # a definition that already states its own priority.
          if v._type == "if" then v // { content = walk v.content; }
          else if v._type == "merge" then v // { contents = map walk v.contents; }
          else v
        else lib.mapAttrs (_: walk) v;

      # Module-system structure at the top level, not option definitions.
      structural = [ "imports" "options" "_module" "_file" "key" "disabledModules" "freeformType" ];
    in
    defs:
      if !(builtins.isAttrs defs) || lib.isDerivation defs
      then throw "flakeLib.mkDefaults: expected an attribute set of option definitions"
      else lib.mapAttrs (name: v: if builtins.elem name structural then v else walk v) defs;
}
