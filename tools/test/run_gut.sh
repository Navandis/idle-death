#!/usr/bin/env bash
# Canonical Linux/Codex entry point for Death Idle's Godot/GUT test suite.
# The wrapper intentionally owns environment validation so test failures are
# reported as Godot/GUT results and setup failures are reported before import.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
GODOT_BIN_FROM_ARG=""
GUT_ARGS=()

while (($#)); do
  case "$1" in
    --godot-bin)
      if (($# < 2)); then
        echo "ERROR: --godot-bin requires a path to a Godot executable." >&2
        exit 64
      fi
      GODOT_BIN_FROM_ARG="$2"
      shift 2
      ;;
    --)
      shift
      GUT_ARGS+=("$@")
      break
      ;;
    *)
      GUT_ARGS+=("$1")
      shift
      ;;
  esac
done

find_godot() {
  if [[ -n "$GODOT_BIN_FROM_ARG" ]]; then
    printf '%s\n' "$GODOT_BIN_FROM_ARG"
  elif [[ -n "${GODOT_BIN:-}" ]]; then
    printf '%s\n' "$GODOT_BIN"
  elif command -v godot >/dev/null 2>&1; then
    command -v godot
  elif command -v godot4 >/dev/null 2>&1; then
    command -v godot4
  else
    return 1
  fi
}

if ! GODOT_BIN_PATH="$(find_godot)"; then
  echo "ERROR: Godot 4.7.x was not found. Set GODOT_BIN, pass --godot-bin, or add godot/godot4 to PATH." >&2
  exit 127
fi
if [[ ! -x "$GODOT_BIN_PATH" ]]; then
  echo "ERROR: Godot executable is not runnable: $GODOT_BIN_PATH" >&2
  exit 126
fi

VERSION_OUTPUT="$($GODOT_BIN_PATH --version 2>&1 || true)"
if [[ ! "$VERSION_OUTPUT" =~ ^4\.7(\.|-|$) ]]; then
  echo "ERROR: Death Idle requires Godot 4.7.x for M00 tests; detected: $VERSION_OUTPUT" >&2
  exit 65
fi

echo "Death Idle test harness"
echo "Repository root: $REPO_ROOT"
echo "Godot executable: $GODOT_BIN_PATH"
echo "Godot version: $VERSION_OUTPUT"

if ((${#GUT_ARGS[@]})); then
  for arg in "${GUT_ARGS[@]}"; do
    if [[ "$arg" == -gtest* ]]; then
      # GUT appends -gtest entries to configured directories.  Clearing -gdir
      # keeps focused script runs focused while still loading shared config.
      GUT_ARGS=("-gdir=" "${GUT_ARGS[@]}")
      break
    fi
  done
fi

cd "$REPO_ROOT"
"$GODOT_BIN_PATH" --headless --path "$REPO_ROOT" --import
"$GODOT_BIN_PATH" --headless --path "$REPO_ROOT" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "${GUT_ARGS[@]}"
