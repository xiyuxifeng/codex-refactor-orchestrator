#!/usr/bin/env bash
set -euo pipefail

package_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-$(pwd)}"

if [[ ! -d "$target" ]]; then
  echo "Target directory does not exist: $target" >&2
  exit 1
fi

mkdir -p "$target/.agents" "$target/.codex"

cp -R "$package_root/.agents/." "$target/.agents/"
cp -R "$package_root/.codex/agents" "$target/.codex/"

source_config="$package_root/.codex/config.toml"
target_config="$target/.codex/config.toml"

if [[ ! -f "$target_config" ]]; then
  cp "$source_config" "$target_config"
  echo "Installed .codex/config.toml"
else
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup="$target/.codex/config.toml.backup-$timestamp"
  cp "$target_config" "$backup"
  echo "Existing .codex/config.toml preserved."
  echo "Backup created: $backup"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to merge missing [agents] settings safely." >&2
    echo "No changes were made to $target_config." >&2
    exit 1
  fi

  python3 - "$target_config" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()

required = {
    "max_threads": "4",
    "max_depth": "1",
    "job_max_runtime_seconds": "1800",
}

section_start = None
section_end = len(lines)
for i, raw in enumerate(lines):
    stripped = raw.strip()
    if stripped == "[agents]":
        section_start = i
        continue
    if section_start is not None and i > section_start and stripped.startswith("[") and stripped.endswith("]"):
        section_end = i
        break

added = []
preserved = []

if section_start is None:
    if lines and lines[-1].strip():
        lines.append("")
    lines.append("[agents]")
    for key, value in required.items():
        lines.append(f"{key} = {value}")
        added.append(f"agents.{key} = {value}")
else:
    present = {}
    for raw in lines[section_start + 1:section_end]:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        present[key.strip()] = value.strip()

    insert_at = section_end
    additions = []
    for key, value in required.items():
        if key in present:
            preserved.append(f"agents.{key} = {present[key]}")
        else:
            additions.append(f"{key} = {value}")
            added.append(f"agents.{key} = {value}")

    if additions:
        lines[insert_at:insert_at] = additions

path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

for item in added:
    print(f"Added missing setting: {item}")
for item in preserved:
    print(f"Preserved existing setting: {item}")
if not added:
    print("No [agents] settings needed to be added.")
PY
fi

echo "Installed:"
echo "  $target/.agents/skills/refactor-orchestrator"
echo "  $target/.codex/agents"
echo "  $target/.codex/config.toml"
echo
echo "Validate from repository root with:"
echo "  bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh"
