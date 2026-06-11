# Codex Refactor Orchestrator

让 **GPT-5.5 负责规划、架构和 Review**，让 **GPT-5.4 mini subagents 负责边界明确的实现与测试**。

A repository-scoped Codex Skill for staged software refactors.

```text
GPT-5.5 parent
├── optional GPT-5.4 mini Explorer agents
├── bounded GPT-5.4 mini Executor agents
└── GPT-5.5 review and stage acceptance
```

## 这个项目解决什么问题？

当重构任务很大时，全部交给 GPT-5.5 往往会：

- 消耗较多 Codex Plan / credits；
- 让单个 Session 上下文越来越长；
- 把规划、实现和 Review 混在同一个上下文中；
- 更容易产生范围漂移和重复实现。

这个 Skill 会让 Codex：

1. 先由 GPT-5.5 检查代码并制定计划；
2. 判断是否需要只读 Explorer；
3. 冻结架构、Schema、API 和迁移契约；
4. 把边界明确的实现任务交给 GPT-5.4 mini Executor；
5. 保存 diff、测试和交接记录；
6. 最后由 GPT-5.5 检查真实改动并验收 Stage。

## 适合什么项目？

适合：

- 有 TaskList、Issue、RFC 或阶段计划的重构；
- 跨前端、后端、数据库或任务系统的改造；
- 需要迁移旧数据、退役旧入口或保持兼容；
- 希望减少 GPT-5.5 的机械实现工作；
- 需要多 Agent 协作但又不希望过度并行。

不太适合：

- 只修改一两个文件的小修复；
- 没有明确目标或验收标准的探索任务；
- 希望 Agent 无限制自主修改整个仓库的场景。

# 5 分钟快速开始

## 1. 安装到目标项目

```bash
git clone git@github.com:xiyuxifeng/codex-refactor-orchestrator.git
cd codex-refactor-orchestrator

./install.sh /path/to/your-project
```

`/path/to/your-project` 必须是准备重构的目标仓库根目录。

安装后，目标项目会新增：

```text
.agents/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

### 已有 `.codex/config.toml` 时会怎样？

安装脚本会自动进行**非破坏性合并**：

1. 创建时间戳备份，例如 `.codex/config.toml.backup-20260611-153000`；
2. 保留用户已有的配置和值；
3. 只补充缺失的 `[agents]` 和缺失字段；
4. 输出哪些字段被新增、哪些已有值被保留。

通常不需要用户手动编辑。只有安装提示缺少 `python3`、配置文件语法异常，或你希望修改默认值时才需要手动处理。

需要的配置为：

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

配置含义：

| 配置 | 含义 | 默认值说明 |
|---|---|---|
| `max_threads` | 同一父 Session 最多可同时运行的 Agent 线程数量，包含并发 subagents | `4` 用于限制并发、文件冲突和 Token 消耗；不是要求每次都启动 4 个 Agent |
| `max_depth` | Agent 委派的最大嵌套深度 | `1` 表示只有 GPT-5.5 主 Agent 可以创建直接 subagent，mini subagent 不能继续创建孙 Agent |
| `job_max_runtime_seconds` | 批量 Agent worker 的默认最长运行秒数 | `1800` 等于 30 分钟，主要用于 `spawn_agents_on_csv` 一类批量 worker，不是所有普通 subagent 的统一强制超时 |

安装脚本不会覆盖已有字段。例如已有 `max_threads = 2` 时会保留 `2`，只补充其他缺失项。

## 2. 验证安装

```bash
cd /path/to/your-project

bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

- `validate-install.sh` 检查文件和配置是否正确。
- `runtime-probe.sh` 检查当前环境，但不能单独证明子 Agent 实际使用了指定模型。

## 3. 启动 GPT-5.5 主 Agent

```bash
codex -m gpt-5.5
```

建议一个 Stage 使用一个新的 GPT-5.5 Session。

## 4. 粘贴第一个 Prompt

项目已有 TaskList：

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
5. Execute tasks by dependency batch.
6. Review the actual git diff and verification output.
7. Do not mark the Stage complete without evidence.
```

项目没有 TaskList：

```text
Use the refactor-orchestrator skill.

Choose and explicitly spawn subagents according to the Skill rules.
Do not rely on implicit delegation.
Use the minimum viable number of agents.

Create a staged refactor plan for this request:
<describe your request>

Inspect the repository first.
Define the target behavior, affected files, dependencies,
verification commands, risks, and acceptance criteria.
Then execute only bounded tasks through mini subagents.
```

## 5. 接下来会自动发生什么？

```text
读取需求和代码
→ 判断是否需要 Explorer
→ 冻结架构与契约
→ 创建 Task Card
→ 显式创建 Executor mini
→ 实现并运行测试
→ 保存 diff / test / handoff
→ GPT-5.5 Review
→ Stage 验收
```

你通常不需要手工决定每个 Task 使用哪个 Agent。

## 6. 如何确认它真的生效？

观察 Codex 是否实际显示：

- 使用了 `refactor-explorer-mini` 或 `refactor-executor-mini`；
- 子 Agent 模型为 GPT-5.4 mini；
- Explorer 是只读；
- Executor 只修改 Task Card 允许的范围；
- GPT-5.5 最后检查了真实 `git diff` 和测试结果。

如果 native subagents 无法使用或模型无法验证，Skill 应切换到 **single-controller fallback**，而不是假装已使用 subagent。

# 哪些事情自动完成，哪些需要你决定？

| 事项 | Skill / 主 Agent | 用户 |
|---|---|---|
| 是否需要 Explorer | 自动判断 | 通常无需处理 |
| 如何拆 Task | 自动生成 | 可 Review |
| 是否并行 | 按路径和依赖判断 | 通常无需处理 |
| 创建 mini subagent | 需要时显式创建 | 只需在 Prompt 中授权 |
| 运行测试和检查 diff | 自动执行 | 查看结果 |
| 架构或产品方向冲突 | 给出证据和选项 | 需要决定 |
| Stage 是否通过 | GPT-5.5 给出验收结论 | 可最终确认 |

# 核心规则

- 小型局部任务可以不创建 subagent，由 GPT-5.5 直接完成。
- 默认使用最少 Agent 数量。
- Explorer 只用于不清楚的调用链或全仓调查。
- Executor 只能执行契约已冻结、范围明确的 Task。
- 同一个 Task 最多三轮修复。
- 不并行修改同一文件、Schema、API 或公共契约。
- 子 Agent 声称完成，不等于 Stage 已通过。
- 最终验收必须检查真实 diff、测试和迁移结果。

# 常见问题

## 没有创建 subagent，是否说明 Skill 没生效？

不一定。小型局部任务的最小 subagent 数量可以为 0。

但对适合委派的中大型任务，如果 Codex 只说“可以使用 subagent”却没有实际 spawn，请确认 Prompt 中包含：

```text
Choose and explicitly spawn subagents according to the Skill rules.
Do not rely on implicit delegation.
```

## 为什么 Runtime Probe 通过后还要确认模型？

脚本只能确认文件、配置和命令存在，不能证明当前运行中的子 Agent 实际使用了 GPT-5.4 mini。

## 已有 `.codex/config.toml` 怎么办？

直接运行安装脚本。脚本会先备份，再保留已有值并补充缺失的 `[agents]` 配置。安装输出会明确显示新增和保留的字段。

## 一个项目应该使用多少个 Agent？

默认：

```text
已知局部任务：0 Explorer + 1 Executor
未知跨模块任务：1～3 Explorer + 默认 1 Executor
```

只有互不修改同一文件和公共契约时才并行 Executor。

## Task 连续失败怎么办？

同一个 Task 最多三轮。第三轮仍失败后停止，交回 GPT-5.5 或用户重新判断契约、范围或实现方向。

# 详细文档

- [中文完整使用说明](docs/01-通用项目使用说明.md)
- [English usage guide](docs/README_EN.md)

## License

MIT
