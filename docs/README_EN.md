# Codex Refactor Orchestrator — Usage Guide

This guide is written for first-time users of Codex Skills and subagents.

# Part A: Quick start

## 1. How it works

```text
GPT-5.5 parent
├── optional refactor-explorer-mini
├── refactor-executor-mini
└── GPT-5.5 review and stage acceptance
```

- GPT-5.5 owns planning, architecture, contracts, review, and acceptance.
- Explorer mini performs bounded read-only repository investigation.
- Executor mini implements approved tasks, adds tests, and runs verification.

## 2. Install

From this repository:

```bash
./install.sh /path/to/your-project
```

The target repository receives:

```text
.agents/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

An existing `.codex/config.toml` is preserved.

## 3. Validate

```bash
cd /path/to/your-project

bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

The first script validates files and configuration. The runtime probe checks the
environment, but static configuration is not proof that a spawned child actually
used GPT-5.4 mini.

## 4. Start the parent

```bash
codex -m gpt-5.5
```

Use one new parent session per stage.

## 5. First prompt

For a project with a task list:

```text
Use the refactor-orchestrator skill.

Choose and explicitly spawn subagents according to the Skill rules.
Do not rely on implicit delegation.
Use the minimum viable number of agents.

Plan and execute Stage 1 from:
docs/Refactor-TaskList.md

Requirements:
1. Read repository instructions first.
2. Inspect the current repository before planning.
3. Freeze architecture and public contracts before delegation.
4. Delegate only bounded implementation tasks.
5. Execute by dependency batch.
6. Preserve diff, test, result, and review artifacts.
7. Review the actual git diff and verification output.
8. Do not accept the Stage without evidence.
```

Without a task list:

```text
Use the refactor-orchestrator skill.

Choose and explicitly spawn subagents according to the Skill rules.
Do not rely on implicit delegation.
Use the minimum viable number of agents.

Create a staged refactor plan for this request:
<describe your request>

Inspect the repository first.
Define target behavior, affected files, dependencies,
verification commands, risks, and acceptance criteria.
Then delegate only bounded tasks to mini subagents.
```

## 6. What happens automatically?

The parent should:

1. read requirements and repository rules;
2. inspect the current implementation;
3. decide whether Explorer is necessary;
4. freeze architecture and contracts;
5. create bounded task cards;
6. explicitly spawn configured mini agents;
7. execute tasks by dependency batch;
8. preserve evidence;
9. review the real diff;
10. accept or reject the stage.

## 7. What requires user input?

User input is normally needed only for:

- product or architecture choices with multiple valid options;
- migration decisions that may lose data;
- scope expansion;
- unresolved acceptance failures;
- unavailable or unverifiable subagent runtime.

## 8. Confirm that subagents actually ran

Check that Codex displays:

- `refactor-explorer-mini` or `refactor-executor-mini`;
- GPT-5.4 mini as the child model;
- read-only effective permissions for Explorer;
- bounded file changes for Executor;
- GPT-5.5 review of the actual diff and test results.

A plan that merely recommends mini agents is not evidence that they were spawned.

# Part B: Operating model

## 9. Minimum viable agents

Default:

```text
Known local task: 0 Explorer + 1 Executor
Unknown cross-module task: 1–3 Explorers, then 1 Executor by default
```

A small task may use no subagent at all and be completed directly by the GPT-5.5 parent.

## 10. Explorer

Use Explorer for:

- unknown call chains;
- repository-wide legacy reference searches;
- duplicate APIs, schemas, or sources of truth;
- read-only deletion checks.

Do not use Explorer for a known local edit.

## 11. Executor

Spawn Executor only when:

- the task has one objective;
- contracts are frozen;
- allowed and forbidden paths are explicit;
- dependencies are complete;
- verification commands are known;
- escalation conditions are defined.

## 12. Parallel safety

Parallelize only when tasks do not modify the same files or public contracts.

Run dependent work serially:

```text
domain model
→ migration
→ API schema
→ generated/frontend types
→ integration tests
```

## 13. Synchronization

Agents synchronize through:

- explicit parent-to-child task cards;
- the shared working tree;
- durable contracts and handoffs;
- structured child results;
- parent review of `git status`, `git diff`, and test output.

Children do not automatically inherit all parent context.

# Part C: Reliability

## 14. Runtime probe

Run after installation or a Codex upgrade:

```bash
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

It checks environment readiness, not actual model execution.

## 15. Three-round fix limit

```text
Round 1: implementation
Round 2: targeted correction
Round 3: final bounded correction
```

After round three, stop and escalate.

## 16. Per-round artifacts

```bash
bash .agents/skills/refactor-orchestrator/scripts/capture-round-artifacts.sh TASK_ID ROUND
```

Preserve diff, tests, status, result, and review evidence.

## 17. Single-controller fallback

If native subagents or their actual models cannot be verified:

- keep GPT-5.5 as the controller;
- generate the same plans and task cards;
- provide manual GPT-5.4 mini session commands;
- never claim that mini subagents ran without evidence.

## 18. Review

For a large or high-risk stage, start a fresh GPT-5.5 review session and provide:

- requirement;
- stage plan and contracts;
- task cards and handoffs;
- diff range;
- verification evidence.

# Part D: Troubleshooting

## Skill not discovered

Confirm this path exists in the target repository:

```text
.agents/skills/refactor-orchestrator/SKILL.md
```

Then run the validation script.

## No subagent was spawned

A small task may require zero subagents. For a delegable task, include:

```text
Choose and explicitly spawn subagents according to the Skill rules.
Do not rely on implicit delegation.
```

## Child model cannot be verified

Use single-controller fallback.

## Explorer wrote files

The parent session may have applied a runtime permission override. Avoid unrestricted
full-access/yolo mode for strict read-only investigation.

## Token control

- avoid Explorer for known files;
- start with one Executor;
- send only task-specific context;
- do not repeat repository-wide searches;
- limit one task to three rounds;
- use one GPT-5.5 session per stage.
