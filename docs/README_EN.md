# General Usage Guide

## Workflow

1. Start one GPT-5.5 parent session per stage.
2. Inspect repository rules and current code.
3. Use zero explorers for known local tasks.
4. Use one to three read-only explorers only for independent unknown areas.
5. Freeze architecture and public contracts.
6. Create bounded task cards.
7. Use one executor by default.
8. Parallelize only non-overlapping paths and contracts.
9. Preserve diff, test, result, and review artifacts for each round.
10. Stop after three failed fix rounds.
11. Review the actual diff with GPT-5.5.
12. Accept the stage only with evidence.

## Runtime probe

Static TOML is not runtime proof. Verify the active parent model, Skill discovery,
custom-agent discovery, native subagent support, effective permissions, and the
actual spawned model.

## Fallback

When native subagents cannot be verified, keep GPT-5.5 as the controller,
generate task cards, and run separate manual GPT-5.4 mini sessions.

## Example prompt

```text
Use the refactor-orchestrator skill.

Plan and execute Stage 2 from docs/Refactor-TaskList.md.
Run the runtime probe first.
Use the minimum viable number of lanes.
Freeze contracts before delegation.
Preserve per-round artifacts.
Stop after the configured fix-round limit.
Review the actual diff before stage acceptance.
```
