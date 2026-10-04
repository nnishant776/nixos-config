# Evaluates every system output without --impure, so that an impure read
# added to a shared module fails here rather than in an automated
# rebuild. This must never pass --impure itself.
{ pkgs }:
pkgs.writeShellApplication {
  name = "check-purity";
  runtimeInputs = [ ];
  text = ''
    flakePath="''${1:-.}"

    failures=0
    checked=0

    for outputAttr in nixosConfigurations darwinConfigurations; do
      # Enumeration failing and the output simply being absent are
      # different things: a Linux-only configuration legitimately has no
      # darwinConfigurations, and reporting that as a failure — silently,
      # which is what swallowing stderr here would do — makes the guard
      # untrustworthy.
      # stdout only: nix writes warnings such as "Git tree is dirty" to
      # stderr, and folding those into this value turns each word of the
      # warning into a phantom host name. On failure the command is
      # re-run to capture the diagnostic.
      if ! enumeration="$(nix eval --json "''${flakePath}#''${outputAttr}" --apply builtins.attrNames 2>/dev/null)"; then
        enumerationError="$(nix eval --json "''${flakePath}#''${outputAttr}" --apply builtins.attrNames 2>&1 || true)"
        case "''${enumerationError}" in
          *"does not provide attribute"*)
            echo "SKIP ''${outputAttr} (not present in ''${flakePath})"
            ;;
          *)
            echo "FAIL ''${outputAttr} (could not enumerate)"
            echo "''${enumerationError}" >&2
            failures=$((failures + 1))
            ;;
        esac
        continue
      fi

      names="$(printf '%s' "''${enumeration}" | tr -d '[]"' | tr ',' '\n')"

      # shellcheck disable=SC2086 # one host per line is the intent
      for name in ''${names}; do
        if [ -n "''${name}" ]; then
          target="''${outputAttr}.''${name}.config.system.build.toplevel.drvPath"
          checked=$((checked + 1))
          if output="$(nix eval --raw "''${flakePath}#''${target}" 2>&1)"; then
            echo "PASS ''${outputAttr}.''${name}"
          else
            echo "FAIL ''${outputAttr}.''${name}"
            echo "''${output}" >&2
            failures=$((failures + 1))
          fi
        fi
      done
    done

    if [ "''${failures}" -gt 0 ]; then
      echo "check-purity: ''${failures} target(s) failed to evaluate purely" >&2
      exit 1
    fi

    # A guard that checked nothing has not passed.
    if [ "''${checked}" -eq 0 ]; then
      echo "check-purity: found no system outputs to check in ''${flakePath}" >&2
      exit 1
    fi

    echo "check-purity: all ''${checked} system output(s) evaluate purely"
  '';
}
