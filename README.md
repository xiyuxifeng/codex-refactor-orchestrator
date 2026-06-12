# Codex Refactor Orchestrator

让 Parent Agent 负责规划、架构和最终 Review，让 mini subagents 只承担边界明确、确实值得委派的调查、实现与测试。

```text
Parent
├── optional Explorer mini
├── optional Executor mini
└── Parent semantic review and acceptance
```

## 它解决什么问题

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

## 委派不是自动发生

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

## 适合什么项目

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

# 5 分钟快速开始

## 1. 安装到目标仓库根目录

```bash
git clone git@github.com:xiyuxifeng/codex-refactor-orchestrator.git
cd codex-refactor-orchestrator
bash install.sh /path/to/your-project
```

推荐使用 `bash install.sh`，避免 `zsh: permission denied: ./install.sh`。

安装后新增：

```text
.agents/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

已有 `.codex/config.toml` 时，安装器会先备份，再保留已有值，只补充缺失的 `[agents]` 配置。通常无需手工编辑。

默认配置：

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

`max_threads` 是并发上限，不是要求启动 4 个 Agent。

## 2. 验证

```bash
cd /path/to/your-project
bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

`runtime-probe.sh` 只检查预期运行条件，不能单独证明实际子 Agent 模型或有效权限。

## 3. 启动 Parent

```bash
codex -m gpt-5.5
```

建议一个 Stage 或一个紧密关联的 Task 组使用一个新 Parent Session。

## 4. 第一个 Prompt

已有 TaskList：

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

没有 TaskList：

```text
Use the refactor-orchestrator skill.

Explicitly decide whether delegation is justified under the Skill rules.
If justified, explicitly spawn the selected configured subagent or subagents.
If not justified, proceed with the Parent only and record that zero subagents
were selected.
Do not rely on implicit delegation.

Create a staged plan for:
<describe your request>

Inspect repository instructions and current code first.
Define target behavior, contracts, dependencies, verification, risks, and
acceptance. Delegate only bounded tasks that pass the Skill gates.
```

# 风险与执行强度

| 风险 | 默认强度 | 典型执行 |
|---|---|---|
| M1 | lean | Parent 直接做，或 1 个 Executor |
| M2 | standard | Parent 冻结契约，默认 1 个 Executor |
| M3 | assurance | Parent 主导，mini 只做限定支持 |

Agent 软预算：

```text
普通任务：0–1 个 subagent
独立写入任务：最多 2 个 Executor
大型只读审计：最多 3 个 Explorer
```

超出默认预算必须由 Parent 明确说明理由。

# Context 与额度控制

- Parent 读取全局规则和架构文档；
- 子 Agent 只读取 Task Card、适用 `AGENTS.md`、相关代码、测试和冻结契约；
- 不让每个子 Agent 重读完整 TaskList 和全部全局设计文档；
- 优先委派只读调查、测试分析和机械实现；
- 一个 Executor 同时完成实现、局部测试和机械自查；
- 不并行修改同一文件、Schema、API、路由或公共契约；
- Parent 永远负责最终 Review。

# Runtime Truth

必须有证据才能声称：

- 测试或命令已运行并通过；
- diff、迁移或验收已完成；
- Task 或 Stage 已完成。

模型、有效权限和 spawning 细节只有可验证时才报告；否则省略或标记为未独立验证。

只有 native spawning 不可用、child 创建失败，或任务依赖的权限边界无法保证时，才进入 single-controller fallback。仅仅无法确认确切 child model，不需要自动 fallback。

# 核心规则

- 委派是条件性的，不是自动的；
- 0 个 subagent 合法；
- Explorer 优先用于 read-heavy 工作；
- Executor 必须有冻结契约和精确 Task Card；
- 默认使用最少 Agent 数量；
- 同一 Task 最多三轮修复；
- 子 Agent 完成声明不等于验收通过；
- 最终验收检查真实 diff、测试、迁移和用户流程。

# 详细文档

- [中文完整使用说明](docs/01-通用项目使用说明.md)
- [English usage guide](docs/README_EN.md)

## License

MIT
