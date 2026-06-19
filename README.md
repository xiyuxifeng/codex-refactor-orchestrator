# Codex Refactor Orchestrator

A repository-scoped Codex Skill for staged, evidence-based, cost-aware software refactors. The Parent agent owns planning, architecture, semantic review, and final acceptance. Mini subagents are used only for bounded investigation, implementation, and verification work when delegation is justified.

```text
Parent
├── optional Explorer mini
├── optional Executor mini
└── Parent semantic review and acceptance
```

- [完整中文使用说明](docs/01-通用项目使用说明.md)

## 1. What this solves

Large refactors often suffer from:

- overly long Parent sessions;
- mixed planning, search, implementation, and review context;
- unclear subtask boundaries;
- excessive parallel agents causing conflicts and token waste;
- child agents claiming completion without real diff or test evidence.

This Skill is not designed to maximize subagent usage. It is designed to:

1. make the Parent read repository rules and current facts first;
2. freeze architecture, schema, API, migration, permission, and compatibility contracts;
3. explicitly decide whether delegation is worthwhile;
4. delegate only bounded and justified work to mini agents;
5. make the Parent inspect the real worktree, diff, tests, and migration evidence;
6. let only the Parent accept a task or stage.

## 2. Delegation is never implicit

Every use of this Skill must include an explicit delegation decision:

```text
Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.
```

`0 subagents selected` is a valid result. Do not create an agent merely because the Skill is loaded.

Executor delegation is allowed only when all of these are true:

- the objective and expected output are bounded;
- allowed and forbidden paths can be stated;
- dependencies are complete;
- public contracts are frozen;
- verification commands and stopping conditions are known.

At least one real benefit must also exist:

- isolate substantial read-heavy context;
- assign bounded routine work to a lower-cost agent;
- run safe, non-overlapping work in parallel;
- materially reduce high-cost rework risk.

The benefit must exceed coordination and context-transfer cost.

## 3. Suitable projects

Good fit:

- projects with a TaskList, issue, RFC, or staged plan;
- frontend/backend/database/mobile/infrastructure refactors;
- legacy migration, compatibility, or retirement work;
- large repository investigation, call-chain tracing, or test-log analysis;
- tasks where wrong changes are expensive to unwind.

Poor fit:

- simple single-file fixes;
- already-localized bugs;
- small copy or style tweaks;
- open-ended exploration without clear goals or acceptance criteria.

## 4. Five-minute quick start

### 4.1 Install into a target repository root

```bash
git clone git@github.com:xiyuxifeng/codex-refactor-orchestrator.git
cd codex-refactor-orchestrator
bash install.sh /path/to/your-project
```

Use `bash install.sh` to avoid depending on executable permissions and to avoid errors such as `zsh: permission denied: ./install.sh`.

The installer adds:

```text
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
.codex/config.toml
```

When the target repository already has `.codex/config.toml`, the installer creates a timestamped backup, preserves existing values, and adds only missing `[agents]` fields.

If the target project still has the legacy path:

```text
.agents/skills/refactor-orchestrator/
```

remove it after confirming `.codex/skills/refactor-orchestrator/` works. Keeping both paths can make Codex or humans read a stale Skill copy.

### 4.2 Default config

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

- `max_threads`: concurrency ceiling, not the required number of agents.
- `max_depth = 1`: only the Parent should spawn direct subagents.
- `job_max_runtime_seconds`: default maximum runtime for agent jobs.

### 4.3 Validate installation

Run from the target repository root:

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

`runtime-probe.sh` checks expected readiness only. It does not prove the exact child model or effective runtime permissions.

### 4.4 Start the Parent

```bash
cd /path/to/your-project
codex -m gpt-5.5
```

Prefer one fresh Parent session per stage or tightly related task group.

## 5. Current model configuration

| Role | Current model | Reasoning | Configuration |
| --- | --- | --- | --- |
| Parent | `gpt-5.5` | selected by launch or Codex config | `-m/--model`, `/model`, or Codex `config.toml` |
| Explorer mini | `gpt-5.4-mini` | `medium` | `.codex/agents/refactor-explorer-mini.toml` |
| Executor mini | `gpt-5.4-mini` | `medium` | `.codex/agents/refactor-executor-mini.toml` |

Both mini agent config files contain:

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

### 5.1 Change the Parent model

For a new session only:

```bash
codex -m gpt-5.5
# or
codex --model gpt-5.4
```

Inside an active Codex session:

```text
/model
```

To change the default, edit user-level `~/.codex/config.toml` or trusted project-level `.codex/config.toml`:

```toml
model = "gpt-5.5"
```

Launch-time `-m/--model` overrides the configured default.

### 5.2 Change mini models

Edit the installed project copies:

```text
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

Example: run Executor on `gpt-5.4`:

```toml
model = "gpt-5.4"
model_reasoning_effort = "high"
```

Do not casually remove the mini `model` setting. A custom agent without an explicit model may inherit the Parent model, increasing cost and changing the intended Parent/mini split.

After changing models, start a new Codex session and rerun:

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

Static TOML and runtime probe output show expected configuration only. They do not independently prove the exact model used by a spawned child. Available model names depend on the current Codex version, account plan, and authentication method.

## 6. First prompt templates

### 6.1 With a TaskList, stage, or issue

```text
Use the refactor-orchestrator skill.

Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.

Plan and execute only <Task or Stage ID> from:
<task-list-path>

Read repository instructions and inspect the current repository first.
Freeze architecture and public contracts before Executor delegation.
Use bounded Task Cards and dependency batches.
Review the actual git diff and verification output.
Do not mark the Task or Stage complete without evidence.
```

Example:

```text
Use the refactor-orchestrator skill.

Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.

Plan and execute only Stage 1 from:
docs/Refactor-TaskList.md

Read repository instructions and inspect the current repository first.
Freeze architecture and public contracts before Executor delegation.
Use bounded Task Cards and dependency batches.
Review the actual git diff and verification output.
Do not mark the Stage complete without evidence.
```

### 6.2 Without a TaskList

```text
Use the refactor-orchestrator skill.

Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.

Create a bounded refactor plan from the request below, inspect the repository
first, then execute only the first safe batch.

Request:
<describe the refactor request>

Before implementation, identify source-of-truth, public contracts, affected
files, verification commands, and acceptance criteria.
Review the actual git diff and verification output before marking anything
complete.
```

### 6.3 Review-only prompt

```text
Use the refactor-orchestrator skill.

Review the completed changes for <Task or Stage ID>.
Do not implement new scope unless required to fix a blocker.
Inspect the actual git diff, tests, build/typecheck/lint output, migration
or rollback evidence when applicable, source-of-truth uniqueness, and docs or
handoff consistency.

Classify findings as BLOCKER, HIGH, MEDIUM, or LOW.
Clear BLOCKER and required HIGH findings before acceptance.
Return ACCEPTED only when evidence supports it.
```

## 7. Recommended workflow

### 7.1 Understand

The Parent should:

- read the selected task, repository instructions, and constraints;
- inspect branch, baseline commit, and dirty worktree;
- decide whether an Explorer mini is useful;
- summarize current implementation, source-of-truth, legacy paths, tests, and unknowns.

### 7.2 Decide and freeze

The Parent freezes:

- architecture and source-of-truth;
- API, schema, data versioning, permissions, and migration contracts;
- retained, migrated, read-only compatibility, or retired legacy paths;
- verification commands and acceptance evidence;
- dependency order and parallel safety boundaries.

Unfrozen architecture, source-of-truth, migration policy, authorization policy, or algorithm semantics must not be delegated to a mini agent.

### 7.3 Create Task Cards

Every delegated Task Card must include:

- task ID, title, risk level, and single objective;
- prerequisites and baseline;
- required reading and repository rules;
- frozen contracts;
- allowed and forbidden paths;
- implementation requirements;
- verification commands;
- acceptance criteria;
- escalation conditions;
- handoff requirements.

Do not send a child only a broad instruction such as `implement this stage`.

### 7.4 Execute by dependency batch

- Start only ready tasks.
- Parallelize only when paths and contracts do not overlap.
- After each batch, the Parent checks the shared worktree and actual diff.
- Resolve conflicts before the next batch.
- Never accept only a child completion message.

### 7.5 Review and accept

Parent review checks:

- behavior against requirements;
- frontend/backend/database/migration/permission/documentation consistency;
- source-of-truth uniqueness;
- legacy path retention, migration, read-only compatibility, or retirement;
- real evidence for tests, lint, typecheck, build, migration, and E2E;
- unrelated changes, scope drift, and unresolved risks.

A task or stage can be accepted only when the observable flow works, relevant layers agree, required verification actually ran, and no unexplained blocker remains.

## 8. Risk levels and default execution intensity

### M1 — local, explicit, reversible

Typical traits:

- clear goal and files;
- stable contract;
- known tests.

Default: Parent direct, or one Executor mini for mechanical implementation, then Parent review.

### M2 — cross-layer but contractable

Typical traits:

- API / schema / UI / service coordination;
- Parent can freeze public contracts first;
- implementation is mechanical after decisions.

Default: Parent freezes contract, one Executor mini implements, Parent performs semantic review.

### M3 — high-risk or irreversible

Typical traits:

- architecture, migration, security, authorization, time semantics, source-of-truth, deletion, or data repair;
- failure could corrupt data or create duplicate official systems.

Default: Parent leads core implementation and review. Mini agents may only perform tightly bounded investigation or mechanical support.

## 9. Agent soft budget

Default soft budget:

```text
Normal task:             0–1 subagent
Independent write work:  up to 2 Executors
Large read-only audit:   up to 3 Explorers
```

Exceeding the default budget requires an explicit Parent justification. Prefer one meaningful child over many tiny children.

## 10. Parallel safety rules

Parallel execution requires all of these:

- allowed paths do not overlap, or the overlap is read-only;
- public contracts are not modified by multiple tasks at once;
- neither task depends on the other's uncommitted output;
- integration order is known;
- rollback is possible.

Usually serialize:

```text
domain model → migration → API/schema → generated/frontend types → integration tests
shared routes/state stores → deletion or compatibility retirement
```

## 11. Evidence requirements

Real evidence is mandatory for:

- commands and tests reported as executed;
- diffs and files reported as changed;
- migrations reported as applied or verified;
- acceptance criteria reported as satisfied;
- task or stage completion decisions.

Runtime metadata must be handled carefully:

- report exact model, effective permissions, or spawning details only when evidence supports them;
- otherwise use `unknown` or `not independently verified`;
- inability to verify the exact child model does not necessarily block a task, but must not be presented as verified.

## 12. Artifacts directory

For substantial work, use:

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

Initialize state:

```bash
bash .codex/skills/refactor-orchestrator/scripts/init-refactor-state.sh <stage-id>
```

Capture diff, status, and test logs after an implementation or fix round:

```bash
bash .codex/skills/refactor-orchestrator/scripts/capture-round-artifacts.sh <task-id> <round>
```

## 13. Fix-round limit

For one delegated task:

```text
Round 1: initial implementation
Round 2: targeted correction
Round 3: final bounded correction
```

After three failed or incomplete rounds, stop, mark the task blocked, preserve evidence, and return control to the Parent or user. Do not broaden the scope to force completion.

## 14. Single-controller fallback

Use fallback when native subagents are unavailable, child spawning fails, or a required permission boundary cannot be guaranteed:

1. keep the Parent as the only active controller;
2. still produce the plan, contracts, Task Cards, and handoffs;
3. do not pretend mini agents were used;
4. let the Parent execute directly, or provide manual mini-session commands;
5. return all diffs and evidence to the Parent for review.

Fallback preserves the workflow but reduces automation.

## 15. FAQ

### Why does Codex say it cannot find `refactor-orchestrator`?

First check whether the target project has:

```text
.codex/skills/refactor-orchestrator/SKILL.md
```

If it only has the legacy path:

```text
.agents/skills/refactor-orchestrator/SKILL.md
```

rerun the installer or manually migrate the Skill to `.codex/skills/refactor-orchestrator/`, then start a new Codex session.

### Are subagents required?

No. The Skill explicitly allows `0 subagents selected`. Parent-only execution is often better for small tasks, unclear boundaries, unfrozen contracts, or tasks where delegation cost is higher than the benefit.

### Is GPT-5.5 required?

GPT-5.5 is recommended for architecture, migration, authorization, source-of-truth, deletion, final review, and stage acceptance. Bounded mechanical implementation can be delegated to mini agents after contracts are frozen.

### Do installed projects update automatically when this source repository changes?

No. Installed Skill and agent files are copies. Rerun:

```bash
bash install.sh /path/to/your-project
```

or manually sync:

```text
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

### Should the old `.agents/skills` path be kept?

No. The canonical path is:

```text
.codex/skills/refactor-orchestrator/
```

After confirming the new path works, remove the old copy:

```bash
rm -rf .agents/skills/refactor-orchestrator
```

## 16. More documentation

- [Installation guide](INSTALL.md)
- [English quick guide](README_EN.md)
- [Full English usage guide](docs/README_EN.md)
- [Generic start prompt example](examples/generic-project/start-prompt.txt)
