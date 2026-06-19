#!/usr/bin/env bash
set -euo pipefail

status=0

echo "# Refactor Orchestrator Runtime Probe"
echo

if command -v codex >/dev/null 2>&1; then
  echo "Codex executable: $(command -v codex)"
  codex --version 2>/dev/null || true
else
  echo "Codex executable: NOT FOUND"
  status=1
fi

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Repository root: $(git rev-parse --show-toplevel)"
else
  echo "Repository root: NOT IN A GIT REPOSITORY"
  status=1
fi

required=(
  ".codex/skills/refactor-orchestrator/SKILL.md"
  ".codex/agents/refactor-explorer-mini.toml"
  ".codex/agents/refactor-executor-mini.toml"
)

for path in "${required[@]}"; do
  if [[ -f "$path" ]]; then
    echo "Found: $path"
  else
    echo "Missing: $path"
    status=1
  fi
done

echo
if [[ -d ".agents/skills/refactor-orchestrator" ]]; then
  echo "Legacy path still exists: .agents/skills/refactor-orchestrator"
  echo "Use .codex/skills/refactor-orchestrator as the canonical installed skill path."
  status=1
fi

echo

echo "Manual runtime confirmations still required:"
echo "- Active parent model is GPT-5.5"
echo "- Project-level configuration is trusted and loaded"
echo "- Native subagent spawning is available in the current Codex session"
echo "- Explorer effective permissions remain read-only"
echo "- Spawned custom agents actually use GPT-5.4 mini"
echo
echo "If any item cannot be verified, use single-controller fallback mode."

exit "$status"