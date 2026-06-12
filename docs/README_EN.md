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
.agents/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
.codex/config.toml
```

Existing `.codex/config.toml` values are preserved. Missing `[agents]` fields are
added after a timestamped backup.

Default settings:

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

`max_threads` is a ceiling, not a target agent count.

## Validate and start

```bash
cd /path/to/your-project
bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
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

1. isolate substantial read-heavy context;
2. move bounded routine work to a lower-cost agent;
3. safely parallelize non-overlapping work;
4. materially reduce expensive rework risk.

Otherwise, the Parent executes directly and records zero subagents.

## Risk and execution intensity

| Risk | Default intensity | Typical flow |
|---|---|---|
| M1 | lean | Parent direct or one Executor |
| M2 | standard | Parent contract, one Executor by default, Parent review |
| M3 | assurance | Parent-led, mini only for tightly bounded support |

The Parent may override the default intensity with a written reason.

## Soft agent budget

```text
Normal task:             0–1 subagent
Independent write work:  up to 2 Executors
Large read-only audit:   up to 3 Explorers
```

Exceeding this default budget requires explicit Parent justification.

## Context budget

The Parent reads global repository instructions, TaskLists, architecture, and
migration documents.

A child reads only:

- its Task Card;
- applicable root and nested `AGENTS.md` files;
- explicitly scoped implementation files;
- directly affected tests;
- frozen contract references and upstream handoffs.

Do not require every child to reread the full repository TaskList and all global
design documents. The Task Card controls scope; current code and tests remain
implementation facts. Contradictions must be escalated.

## Task Card requirements

Each delegated card includes:

- task ID, risk, and one objective;
- dependencies and baseline;
- applicable instructions and required reading;
- frozen contracts;
- allowed and forbidden paths;
- implementation requirements;
- test, lint, build, and migration commands;
- acceptance and escalation conditions;
- structured handoff requirements.

Never delegate with only `implement this stage`.

## Parallel safety

Parallel execution requires non-overlapping paths and contracts, no dependency
on another task's uncommitted output, known integration order, and rollback.

Serialize:

```text
domain model
→ migration
→ API/schema
→ generated/frontend types
→ integration tests
```

Also serialize shared routes/state, shared tables, schema generation, deletion,
and compatibility retirement.

## Runtime truth

Evidence is mandatory for commands, tests, diffs, migrations, acceptance, and
completion claims.

Exact model identity, effective permissions, and spawning details are reported
only when verifiable. Otherwise omit them or mark them as not independently
verified.

Use single-controller fallback only when native spawning is unavailable, child
creation fails, or a required permission boundary cannot be guaranteed. Failure
to verify an exact child model name alone does not require fallback if the child
actually ran.

If strict read-only permission cannot be trusted, do not spawn that Explorer.
Perform the investigation in the Parent or use an approved alternative.

## Parent review

The Parent reviews the actual worktree and combined diff, behavior, cross-layer
contracts, migrations and rollback, source-of-truth uniqueness, traceability,
partial/error states, test quality, retirement conditions, unrelated changes,
and scope drift.

A child `completed` result is not acceptance evidence.

## Three-round limit

```text
Round 1: initial implementation
Round 2: targeted correction
Round 3: final bounded correction
```

After round three, stop, preserve evidence, mark blocked, and return control to
the Parent or user. Do not broaden scope to force completion.

## Temporary state

```text
.codex/refactor-state/<stage-id>/
├── stage-plan.md
├── manifest.yaml
├── contracts/
├── tasks/
├── handoffs/
├── reviews/
└── artifacts/
```

## Token-control checklist

- Parent handles small known tasks directly.
- Prefer read-heavy and mechanical delegation.
- Start with zero or one child.
- Do not repeat global-document reads in each child.
- Combine implementation, tests, and mechanical self-review in one Executor.
- Use one Parent session per bounded stage or tightly related task group.
- Keep the Parent as final reviewer.
