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
.codex/skills/refactor-orchestrator/
.codex/agents/refactor-explorer-mini.toml
.codex/agents/refactor-executor-mini.toml
```

已有 `.codex/config.toml` 时，安装器会先备份，再保留已有值，只补充缺失的 `[agents]` 配置。通常无需手工编辑。

如果目标项目仍有旧路径：

```text
.agents/skills/refactor-orchestrator/
```

请在确认 `.codex/skills/refactor-orchestrator/` 可用后删除旧路径，避免 Codex 或使用者读取到过期副本。

默认配置：

```toml
[agents]
max_threads = 4
max_depth = 1
job_max_runtime_seconds = 1800
```

`max_threads` 是并发上限，不是要求启动 4 个 Agent。

## 2. 当前模型配置

默认组合：

| 角色 | 当前模型 | 配置位置 |
| --- | --- | --- |
| Parent | `gpt-5.5` | 启动参数、`/model` 或 Codex `config.toml` |
| Explorer mini | `gpt-5.4-mini` | `.codex/agents/refactor-explorer-mini.toml` |
| Executor mini | `gpt-5.4-mini` | `.codex/agents/refactor-executor-mini.toml` |

两个 mini Agent 默认都使用：

```toml
model = "gpt-5.4-mini"
model_reasoning_effort = "medium"
```

### 修改 Parent 模型

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

### 修改 mini 模型

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

## 3. 验证

```bash
cd /path/to/your-project
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

`runtime-probe.sh` 只检查预期运行条件，不能单独证明实际子 Agent 模型或有效权限。

## 4. 启动 Parent

```bash
codex -m gpt-5.5
```

建议一个 Stage 或一个紧密关联的 Task 组使用一个新 Parent Session。

## 5. 第一个 Prompt

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