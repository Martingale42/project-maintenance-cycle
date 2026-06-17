#!/usr/bin/env bash
#
# install.sh — make the project-maintenance-cycle skill discoverable by symlinking
# its payload (the skill/ subdir) into one or more agent skills directories.
#
# Only the skill/ subdirectory is installed — the repo root (README, lifecycle
# docs, design trail) is deliberately kept out of the loaded skill.
#
# Usage:
#   ./install.sh                 # symlink into every target dir that exists
#   ./install.sh --all           # ...and create any missing target dirs
#   ./install.sh DIR [DIR...]    # install only into the given dir(s)
#   ./install.sh --copy          # copy the payload instead of symlinking
#   ./install.sh --force         # overwrite a non-symlink entry of the same name
#   ./install.sh --uninstall     # remove installs that point at this repo
#   ./install.sh --help
#
# Default targets: ~/.claude/skills  ~/.codex/skills  ~/.agents/skills

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$SCRIPT_DIR/skill"

DEFAULT_TARGETS=("$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills")

MODE="install"   # install | uninstall
METHOD="symlink" # symlink | copy
FORCE=0
CREATE_MISSING=0
EXPLICIT_TARGETS=()

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall|-u) MODE="uninstall" ;;
    --copy)         METHOD="copy" ;;
    --force|-f)     FORCE=1 ;;
    --all)          CREATE_MISSING=1 ;;
    -h|--help)      usage 0 ;;
    -*)             echo "unknown flag: $1" >&2; usage 1 ;;
    *)              EXPLICIT_TARGETS+=("$1") ;;
  esac
  shift
done

# Resolve the skill name from frontmatter (fallback to the directory name).
SKILL_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PAYLOAD/SKILL.md" 2>/dev/null | head -1)"
SKILL_NAME="${SKILL_NAME:-$(basename "$SCRIPT_DIR")}"

if [[ ! -f "$PAYLOAD/SKILL.md" ]]; then
  echo "error: payload not found at $PAYLOAD (expected $PAYLOAD/SKILL.md)" >&2
  exit 1
fi

# Choose targets: explicit args win; otherwise the defaults. Without --all,
# default targets that don't exist yet are skipped (don't create agent dirs for
# agents that aren't installed).
targets=()
if [[ ${#EXPLICIT_TARGETS[@]} -gt 0 ]]; then
  targets=("${EXPLICIT_TARGETS[@]}")
  CREATE_MISSING=1   # an explicitly named dir is created if missing
else
  for d in "${DEFAULT_TARGETS[@]}"; do
    if [[ -d "$d" || $CREATE_MISSING -eq 1 ]]; then targets+=("$d"); fi
  done
fi

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "no target skills directories found (looked for: ${DEFAULT_TARGETS[*]})." >&2
  echo "re-run with --all to create them, or pass a target directory." >&2
  exit 1
fi

points_here() { # $1 = link path; true if it's a symlink resolving into this repo
  [[ -L "$1" ]] && [[ "$(readlink -f "$1")" == "$(readlink -f "$PAYLOAD")" ]]
}

did=0
for dir in "${targets[@]}"; do
  link="$dir/$SKILL_NAME"

  if [[ "$MODE" == "uninstall" ]]; then
    if points_here "$link"; then
      rm "$link"; echo "removed  $link"; did=1
    elif [[ -e "$link" && $FORCE -eq 1 ]]; then
      rm -rf "$link"; echo "removed  $link (--force)"; did=1
    elif [[ -e "$link" ]]; then
      echo "skip     $link (not a symlink to this repo; use --force to remove)"
    else
      echo "skip     $link (nothing installed)"
    fi
    continue
  fi

  # install
  mkdir -p "$dir"
  if [[ -e "$link" && ! -L "$link" && $FORCE -eq 0 ]]; then
    echo "skip     $link (exists and is not a symlink; use --force to overwrite)" >&2
    continue
  fi
  rm -rf "$link"
  if [[ "$METHOD" == "copy" ]]; then
    cp -R "$PAYLOAD" "$link"; echo "copied   $PAYLOAD -> $link"
  else
    ln -s "$PAYLOAD" "$link"; echo "linked   $link -> $PAYLOAD"
  fi
  did=1
done

[[ $did -eq 1 ]] || echo "nothing to do."
echo "skill: $SKILL_NAME"
