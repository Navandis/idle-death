#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GODOT_BIN_ARG=""
GUT_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --godot)
      if [[ $# -lt 2 ]]; then
        echo "error: --godot requires a path to a Godot executable" >&2
        exit 2
      fi
      GODOT_BIN_ARG="$2"
      shift 2
      ;;
    --)
      shift
      GUT_ARGS+=("$@")
      break
      ;;
    *)
      echo "error: unknown wrapper argument '$1' (use -- before GUT arguments)" >&2
      exit 2
      ;;
  esac
done

resolve_godot() {
  if [[ -n "$GODOT_BIN_ARG" ]]; then
    printf '%s\n' "$GODOT_BIN_ARG"
    return 0
  fi
  if [[ -n "${GODOT_BIN:-}" ]]; then
    printf '%s\n' "$GODOT_BIN"
    return 0
  fi
  local candidate
  for candidate in godot4.7 godot47 godot4 godot; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done
  return 1
}

GODOT_BIN_RESOLVED="$(resolve_godot || true)"
if [[ -z "$GODOT_BIN_RESOLVED" ]]; then
  echo "error: Godot 4.7.x was not found. Pass --godot <path>, set GODOT_BIN, or add godot4.7/godot4/godot to PATH." >&2
  exit 127
fi
if [[ ! -x "$GODOT_BIN_RESOLVED" ]] && ! command -v "$GODOT_BIN_RESOLVED" >/dev/null 2>&1; then
  echo "error: resolved Godot executable is not runnable: $GODOT_BIN_RESOLVED" >&2
  exit 127
fi

VERSION_OUTPUT="$($GODOT_BIN_RESOLVED --version 2>&1)"
VERSION_STATUS=$?
echo "Godot executable: $GODOT_BIN_RESOLVED"
echo "Godot version: $VERSION_OUTPUT"
if [[ $VERSION_STATUS -ne 0 ]]; then
  echo "error: could not query Godot version" >&2
  exit $VERSION_STATUS
fi
if [[ ! "$VERSION_OUTPUT" =~ ^4\.7(\.|-|$) ]]; then
  echo "error: expected Godot 4.7.x, got: $VERSION_OUTPUT" >&2
  exit 3
fi

# Import first so parser/resource errors fail before the test runner starts.
echo "Importing project..."
"$GODOT_BIN_RESOLVED" --headless --path "$REPO_ROOT" --editor --quit
IMPORT_STATUS=$?
if [[ $IMPORT_STATUS -ne 0 ]]; then
  echo "error: Godot project import failed with exit code $IMPORT_STATUS" >&2
  exit $IMPORT_STATUS
fi

# GUT owns the final test exit code; the wrapper intentionally returns it unchanged.
echo "Running GUT..."
"$GODOT_BIN_RESOLVED" --headless --path "$REPO_ROOT" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit "${GUT_ARGS[@]}"
GUT_STATUS=$?
echo "GUT exit code: $GUT_STATUS"
exit $GUT_STATUS
