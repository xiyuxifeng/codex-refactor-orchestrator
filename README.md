# Codex Refactor Orchestrator

让 Parent Agent 负责规划、架构和最终 Review，让 mini subagents 只承担边界明确、确实值得委派的调查、实现与测试。

```text
Parent
├── optional Explorer mini
├── optional Executor mini
└── Parent semantic review and acceptance
```

## 1. 它解决什么问题

大型重构容易出现：

- 主 Session 上下文过长；
- 搜索、日志、实现和 Review 混在一起；
- 子任务边界不清导致返工；
- 多 Agent 过度并行造成冲突和额外 Token；
- 子 Agent 自报完成，但缺少真实 diff 和测试证据。

本 Skill 的目标不是“尽可能多用 subagent”，而是：

1. Parent 先读取仓库规则和当前事实；
2. 冻结架构、Schema、API、迁移、权限和兼容契约；
3. 显式判断是否值得委派；
4. 只把合格且有收益的任务交给 mini；
5. Parent 检查真实工作区、diff、测试和迁移；
6. 最后由 Parent 验收 Task 或 Stage。

## 2. 委派不是自动发生

每次使用 Skill，Parent 都必须显式做出委派决策：

```text
Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.
```

`0` 个 subagent 是合法结果。不要因为 Skill 已加载就创建 Agent。

只有同时满足以下条件，Executor 才可以被委派：

- 目标和输出明确；
- 允许/禁止路径可界定；
- 上游依赖完成；
- 公共契约已经冻结；
- 验证命令和停止条件明确。

在此基础上，还必须至少具备一个实际收益：

- 隔离大量只读上下文；
- 用低成本 Agent 承担机械工作；
- 安全并行不重叠任务；
- 显著降低高成本返工风险。

且收益必须大于协调和上下文传递成本。

## 3. 适合什么项目

适合：

- 有 TaskList、Issue、RFC 或阶段计划；
- 跨前端、后端、数据库、移动端或基础设施；
- 需要迁移旧数据、退役旧入口或保持兼容；
- 需要隔离全仓搜索、测试日志和调用链分析；
- 修改错误后的返工代价较高。

不太适合：

- 单文件简单修复；
- 已定位的小 Bug；
- 小范围文案或样式修改；
- 没有明确目标和验收标准的开放式探索。

## 4. 5 分钟快速开始

### 4.1 安装到目标仓库根目录

```bash
git clone git@github.com:xiyuxifeng/codex-refactor-orchestrator.git
cd codex-refactor-orchestrator
bash install.sh /path/to/your-project
```

推荐使用 `bash install.sh`，避免 `zsh: permission denied: ./install.sh`。

安装后新增：

```text
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
.codex/config.toml
```

已有 `.codex/config.toml` 时，安装器会先备份，再保留已有值，只补充缺失的 `[agents]` 配置。通常无需手工编辑。

如果目标项目仍有旧路径：

```text
.agents/skills/refactor-orchestrator/
```

请在确认 `.codex/skills/refactor-orchestrator/` 可用后删除旧路径，避免 Codex 或使用者读取到过期副本。

### 4.2 默认配置

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

- `max_threads`：并发上限，不是要求启动 4 个 Agent。
- `max_depth = 1`：只允许 Parent 创建直接 subagent，避免子代理再创建子代理。
- `job_max_runtime_seconds`：批量 worker 的默认最长运行时间。

### 4.3 验证安装

在目标项目根目录运行：

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

`runtime-probe.sh` 只检查预期运行条件，不能单独证明实际子 Agent 模型或有效权限。

### 4.4 启动 Parent

```bash
cd /path/to/your-project
codex -m gpt-5.5
```

建议一个 Stage 或一个紧密关联的 Task 组使用一个新 Parent Session。

## 5. 当前模型配置

默认组合：

| 角色 | 当前模型 | Reasoning | 配置位置 |
| --- | --- | --- | --- |
| Parent | `gpt-5.5` | 由启动或 Codex 配置决定 | `-m/--model`、`/model`、Codex `config.toml` |
| Explorer mini | `gpt-5.4-mini` | `medium` | `.codex/agents/refactor-explorer-mini.toml` |
| Executor mini | `gpt-5.4-mini` | `medium` | `.codex/agents/refactor-executor-mini.toml` |

两个 mini Agent 默认都使用：

```toml
model = "gpt-5.4-mini"
model_reasoning_effort = "medium"
```

Explorer 另外配置：

```toml
sandbox_mode = "read-only"
```

Executor 另外配置：

```toml
sandbox_mode = "workspace-write"
```

### 5.1 修改 Parent 模型

仅修改本次新 Session：

```bash
codex -m gpt-5.5
# 或
codex --model gpt-5.4
```

在当前 Codex Session 中切换：

```text
/model
```

修改默认模型，可编辑用户级 `~/.codex/config.toml`，或受信任项目中的 `.codex/config.toml`：

```toml
model = "gpt-5.5"
```

启动参数 `-m/--model` 会覆盖配置文件中的默认模型。

### 5.2 修改 mini 模型

编辑目标项目中的：

```text
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

例如把 Executor 改为 `gpt-5.4`：

```toml
model = "gpt-5.4"
model_reasoning_effort = "high"
```

不要随意删除 mini TOML 中的 `model`。省略后，custom agent 可能继承 Parent 模型，从而提高成本并改变原有职责分工。

修改模型后建议新建 Codex Session，并再次运行：

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

注意：静态 TOML 和 runtime probe 只能说明预期配置，不能单独证明某次 child 实际使用的模型。模型名称是否可用还取决于当前 Codex 版本、账号计划和认证方式。

## 6. 第一个 Prompt 模板

### 6.1 有 TaskList / Stage / Issue 时

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

示例：

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

### 6.2 没有 TaskList 时

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

### 6.3 Review 专用 Prompt

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

## 7. 推荐工作流

### 7.1 Understand

Parent 先做：

- 读取任务、仓库说明、约束文档；
- 检查当前分支、baseline commit、dirty worktree；
- 判断是否需要 Explorer mini；
- 整理当前实现、事实源、旧路径、测试入口和未知点。

### 7.2 Decide and freeze

Parent 冻结：

- 架构和 source-of-truth；
- API、Schema、数据版本、权限和迁移契约；
- 哪些旧入口保留、迁移、只读兼容或退役；
- 验证命令和验收证据；
- 任务依赖顺序和并行安全边界。

未冻结的架构、事实源、迁移策略、权限策略和算法语义不能交给 mini 自行决定。

### 7.3 Create Task Cards

每个 delegated Task Card 必须包含：

- task ID、标题、风险级别、单一目标；
- 前置依赖和 baseline；
- 必读文件和仓库规则；
- 已冻结契约；
- allowed paths 和 forbidden paths；
- 实现要求；
- 验证命令；
- 验收标准；
- escalation 条件；
- handoff 要求。

不要只给 child 一句 `implement this stage`。

### 7.4 Execute by dependency batch

- 只启动 ready task；
- 只有路径和契约不重叠时才并行；
- 每个 batch 完成后 Parent 检查共享工作树和实际 diff；
- 解决冲突后再进入下一批；
- 不接受只有 child completion message 的结果。

### 7.5 Review and Accept

Parent Review 检查：

- 行为是否符合需求；
- 前后端、数据库、迁移、权限和文档是否一致；
- source-of-truth 是否唯一；
- 旧入口是否按约束保留、迁移、只读兼容或退役；
- 测试、lint、typecheck、build、migration、E2E 是否有真实证据；
- 是否有无关改动、scope drift、未解释风险。

Task 或 Stage 只有在实际 flow 可观察、相关层一致、必要验证已运行且没有未解释 blocker 时才能 accepted。

## 8. 风险分级与默认执行强度

### M1 — 本地、明确、可回滚

特征：

- 目标和文件清楚；
- 契约稳定；
- 测试命令明确。

默认：Parent 直接做，或一个 Executor mini 做机械实现，Parent Review。

### M2 — 跨层但可契约化

特征：

- 需要 API / Schema / UI / 服务协同；
- Parent 可以先冻结公共契约；
- 实现部分相对机械。

默认：Parent 冻结契约，一个 Executor mini 实现，Parent semantic review。

### M3 — 高风险或不可逆

特征：

- 架构、迁移、安全、权限、时间语义、事实源、删除或数据修复；
- 错误可能破坏数据或产生重复官方系统。

默认：Parent 主导核心实现和 Review，mini 只能做严格限定的调查或机械辅助。

## 9. Agent 软预算

默认软预算：

```text
普通任务：0–1 个 subagent
独立写入任务：最多 2 个 Executor
大型只读审计：最多 3 个 Explorer
```

超过默认预算需要 Parent 写明理由。更推荐“一个有意义的 child”，而不是很多很小的 child。

## 10. 并行安全规则

并行执行必须同时满足：

- allowed paths 不重叠，或重叠部分只读；
- 公共契约不会被多个任务同时修改；
- 两个任务不依赖对方未提交输出；
- 集成顺序明确；
- 可以回滚。

以下内容通常要串行：

```text
领域模型 → migration → API/schema → generated/frontend types → integration tests
共享 routes/state stores → 删除/兼容入口退役
```

## 11. 证据要求

必须提供真实证据的内容：

- 声称执行过的命令和测试；
- 声称修改过的 diff 和文件；
- 声称执行或验证过的 migration；
- 声称满足的验收标准；
- Task 或 Stage 完成结论。

Runtime metadata 要谨慎：

- 只有有证据时才报告精确模型、实际权限或 spawning 细节；
- 无法验证时写 `unknown` 或 `not independently verified`；
- 无法验证 child 精确模型，不一定阻塞任务，但不能假装已验证。

## 12. 产物目录

大型任务建议使用：

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

初始化示例：

```bash
bash .codex/skills/refactor-orchestrator/scripts/init-refactor-state.sh <stage-id>
```

每轮实现/修复后可保存 diff、status 和测试日志：

```bash
bash .codex/skills/refactor-orchestrator/scripts/capture-round-artifacts.sh <task-id> <round>
```

## 13. Fix round 限制

同一个 delegated task：

```text
Round 1: initial implementation
Round 2: targeted correction
Round 3: final bounded correction
```

三轮后仍失败或不完整，应停止，标记 blocked，保留证据，交回 Parent 或用户决策。不要扩大范围强行完成。

## 14. Single-controller fallback

当 native subagents 不可用、child spawning 失败、或必要权限边界无法保证时，使用 fallback：

1. Parent 保持唯一控制者；
2. 仍然产出 plan、contracts、Task Cards、handoffs；
3. 不假装使用了 mini；
4. Parent 直接执行，或提供手动 mini-session 命令；
5. 所有 diff 和证据回到 Parent Review。

Fallback 保留工作流，但减少自动化。

## 15. 常见问题

### 为什么 Codex 说找不到 `refactor-orchestrator`？

优先检查目标项目是否存在：

```text
.codex/skills/refactor-orchestrator/SKILL.md
```

如果只有旧路径：

```text
.agents/skills/refactor-orchestrator/SKILL.md
```

请重新运行安装脚本，或手动迁移到 `.codex/skills/refactor-orchestrator/`，然后新开 Codex Session。

### 是否必须使用 subagent？

不必须。Skill 明确允许 `0 subagents selected`。当任务很小、边界不清、公共契约未冻结、或委派成本更高时，Parent 直接执行更好。

### 是否必须使用 GPT-5.5？

架构、迁移、权限、事实源、删除、最终 Review 和 Stage Acceptance 建议使用 GPT-5.5。普通机械实现可以在契约冻结后交给 mini。

### 修改源仓库后，已安装项目会自动更新吗？

不会。已经安装到目标项目里的 Skill 和 agents 是副本。需要重新运行：

```bash
bash install.sh /path/to/your-project
```

或者手动同步：

```text
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

### 旧 `.agents/skills` 是否还要保留？

不建议长期保留。正式路径是：

```text
.codex/skills/refactor-orchestrator/
```

旧路径只作为迁移提示。确认新路径可用后应删除：

```bash
rm -rf .agents/skills/refactor-orchestrator
```

## 16. 更多文档

- `INSTALL.md`：安装说明。
- `README_EN.md`：英文快速说明。
- `docs/README_EN.md`：英文完整使用说明。
- `docs/01-通用项目使用说明.md`：中文完整使用说明。
- `examples/generic-project/start-prompt.txt`：通用启动 Prompt 示例。