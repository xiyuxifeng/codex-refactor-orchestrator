# Codex Refactor Orchestrator — Usage Guide

A repository-scoped Codex Skill for staged, evidence-based, cost-aware refactors.

```text
Parent agent
├── optional Explorer mini
├── optional Executor mini
└── Parent semantic review and acceptance
```

The goal is not to maximize subagent usage. Delegation is conditional and must
provide more value than its coordination and context-transfer cost.

## Install

```bash
bash install.sh /path/to/your-project
```

Use the target Git repository root. The installer adds:

```text
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
.codex/config.toml
```

Existing `.codex/config.toml` values are preserved. Missing `[agents]` fields are
added after a timestamped backup.

If the target repository still contains the legacy `.agents/skills/refactor-orchestrator`
path, remove that old copy after confirming the `.codex/skills/refactor-orchestrator`
copy works. Keeping both can make Codex or humans read a stale Skill version.

Default settings:

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

`max_threads` is a ceiling, not a target agent count.

## Current model configuration

| Role | Current model | Reasoning | Configuration |
|---|---|---|---|
| Parent | `gpt-5.5` | selected by launch/session/config | `-m/--model`, `/model`, or Codex `config.toml` |
| Explorer mini | `gpt-5.4-mini` | `medium` | `.codex/agents/refactor-explorer-mini.toml` |
| Executor mini | `gpt-5.4-mini` | `medium` | `.codex/agents/refactor-executor-mini.toml` |

Both child agent files currently contain:

```toml
model = "gpt-5.4-mini"
model_reasoning_effort = "medium"
```

Explorer also uses:

```toml
sandbox_mode = "read-only"
```

Executor also uses:

```toml
sandbox_mode = "workspace-write"
```

### Change the Parent model for one new session

```bash
codex -m gpt-5.5
# equivalent
codex --model gpt-5.5
```

For example:

```bash
codex -m gpt-5.4
```

This only affects that launch.

### Change the Parent model in the active session

Use:

```text
/model
```

Choose from the models available to the current Codex version, account, and
authentication method. This does not automatically edit a config file.

### Change the default Parent model

Edit the user-level config:

```text
~/.codex/config.toml
```

A trusted repository may also provide:

```text
<project-root>/.codex/config.toml
```

Set:

```toml
model = "gpt-5.5"
```

A launch-time `-m/--model` value overrides the configured default.

### Change Explorer or Executor models

Edit the installed project copies:

```text
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

Example: run Executor on `gpt-5.4` with higher reasoning effort:

```toml
model = "gpt-5.4"
model_reasoning_effort = "high"
```

Example: keep the mini model but lower reasoning effort:

```toml
model = "gpt-5.4-mini"
model_reasoning_effort = "low"
```

Available model/reasoning combinations depend on the current Codex release,
plan, and authentication method.

Do not remove the child `model` setting casually. A custom agent without an
explicit model may inherit the Parent model, increasing cost and changing the
intended Parent/mini split.

After changing models:

1. save the TOML files;
2. start a new Codex session;
3. rerun:

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

Static TOML and the runtime probe show expected configuration only. They do not
prove the model actually used by a specific spawned child. Report unverified
runtime metadata as `not independently verified`.

Changes made in the `codex-refactor-orchestrator` source repository do not
automatically update copies already installed in other projects. Re-run the
installer or manually synchronize the Skill and `.codex/agents/*.toml` files.
Back up project-specific child configuration before reinstalling.

## Validate and start

```bash
cd /path/to/your-project
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
codex -m gpt-5.5
```

The runtime probe validates expected readiness. It does not by itself prove the
actual child model or effective runtime permissions.

## First prompt

```text
Use the refactor-orchestrator skill.

Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.

Plan and execute only <Task or Stage ID> from:
<task-list-path>

Read repository instructions and inspect current code first.
Freeze architecture and public contracts before Executor delegation.
Use bounded Task Cards and dependency batches.
Review the actual worktree, git diff, and verification output.
Do not mark completion without evidence.
```

## Delegation eligibility gate

Before Executor delegation, all must be true:

- objective and output are bounded;
- allowed and forbidden paths are explicit;
- dependencies are complete;
- public contracts are frozen;
- verification and escalation conditions are known.

Unresolved architecture, source-of-truth, migration policy, authorization, and
algorithm semantics remain Parent responsibilities.

## Delegation benefit gate

Delegate only when at least one material benefit exists and exceeds coordination
cost:

- isolate substantial read-heavy context;
- assign bounded routine work to a lower-cost agent;
- run independent non-overlapping work safely in parallel;
- reduce high-cost rework risk.

Zero subagents is always valid when delegation is not justified.

## Acceptance rule

The Parent must inspect the actual worktree, diff, verification output, and
handoff evidence before accepting a task or stage. Child completion messages are
not acceptance evidence by themselves.