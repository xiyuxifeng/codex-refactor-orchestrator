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

if [[ -f "$target/.codex/config.toml" ]]; then
  echo "Existing .codex/config.toml preserved."
  echo "Review and merge settings from: $package_root/.codex/config.toml"
else
  cp "$package_root/.codex/config.toml" "$target/.codex/config.toml"
  echo "Installed .codex/config.toml"
fi

echo "Installed:"
echo "  $target/.agents/skills/refactor-orchestrator"
echo "  $target/.codex/agents"
echo
echo "Validate from repository root with:"
echo "  bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh"
