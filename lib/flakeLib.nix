# Helpers shared by this flake's own modules, threaded in as `flakeLib` via
# specialArgs / extraSpecialArgs by lib/mkHost.nix and lib/mkUser.nix.
{ lib }:
rec {
  # conf.users.accounts.<name>.manageAccount is nullOr bool: null resolves by
  # platform, since a NixOS machine declares accounts but a Mac gets them from
  # MDM. An explicit value wins.
  accountManaged = platform: user:
    if user.manageAccount != null
    then user.manageAccount
    else platform != "darwin";

  # Recursively marks a module's option definitions as lib.mkDefault, so a
  # host (or per-user module) can override them with a plain assignment
  # instead of colliding with them:
  #
  #   config = flakeLib.mkDefaults {
  #     time.timeZone = "Asia/Kolkata";
  #     services.openssh.settings.PermitRootLogin = "no";
  #   };
  #
  # Lists are left untouched, since list definitions concatenate rather than
  # replace — defaulting one would make any other definition replace it
  # outright instead of adding to it. Use `lib.mkDefault [ ... ]` directly if
  # you want replace-semantics for a list. Anything already carrying a
  # priority is left as written. Opaque values (derivations, store paths,
  # functions, freeform settings blobs) are not descended into, since that
  # would embed override markers inside the data; wrap those explicitly at the
  # option boundary instead.
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
          # Look through mkIf/mkMerge, but never re-prioritise a definition
          # that already states its own priority.
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
