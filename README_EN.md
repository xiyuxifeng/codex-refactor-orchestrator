# Codex Refactor Orchestrator

A repository-scoped Codex Skill for staged software refactors.

## Model pattern

```text
GPT-5.5 parent
├── optional read-only GPT-5.4 mini explorers
├── bounded GPT-5.4 mini executors
└── GPT-5.5 semantic review and stage acceptance
```

## Goals

- keep architecture decisions with the stronger parent model
- delegate deterministic implementation to lower-cost mini agents
- use the minimum viable number of agents
- preserve task cards, diffs, test logs, handoffs, and reviews
- stop repeated fix loops after a bounded number of rounds
- fall back safely when native subagents are unavailable

## Installation

Install the Skill under `.codex/skills/refactor-orchestrator` and custom agents under `.codex/agents` by running:

```bash
bash install.sh /path/to/repository
```

The installer creates or updates these paths:

```text
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
.codex/config.toml
```

When the target repository already has `.codex/config.toml`, the installer creates a backup, preserves existing values, and adds only missing `[agents]` settings.

If the target still contains the legacy `.agents/skills/refactor-orchestrator` path, remove it after confirming the `.codex/skills` copy works to avoid stale duplicate Skill copies.

Validate:

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

Start the parent:

```bash
codex -m gpt-5.5
```

See `docs/README_EN.md` for the full guide.