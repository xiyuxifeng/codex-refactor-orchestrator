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

Copy `.agents/` and `.codex/` to the repository root, or run:

```bash
bash install.sh /path/to/repository
```

When the target repository already has `.codex/config.toml`, the installer creates a backup, preserves existing values, and adds only missing `[agents]` settings.

Validate:

```bash
bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

Start the parent:

```bash
codex -m gpt-5.5
```

See `docs/README_EN.md` for the full guide.
