# Installation

## 推荐：安装脚本

```bash
bash install.sh /path/to/your/repository
```

使用 `bash install.sh` 不依赖 `install.sh` 的可执行权限，避免出现：

```text
zsh: permission denied: ./install.sh
```

脚本会安装：

- `.codex/skills/refactor-orchestrator`
- `.codex/agents`
- `.codex/config.toml`

如果目标仓库已有 `.codex/config.toml`，脚本会：

1. 创建时间戳备份；
2. 保留已有字段和值；
3. 只补充缺失的 `[agents]` 配置；
4. 在终端显示新增和保留的字段。

如果目标仓库仍存在旧路径 `.agents/skills/refactor-orchestrator`，安装脚本会提示迁移警告。确认 `.codex/skills/refactor-orchestrator` 可用后，应删除旧路径，避免 Codex 或使用者读取到过期副本。

## 手动安装

复制或创建以下目录到目标仓库根目录：

```text
.codex/
├── skills/
│   └── refactor-orchestrator/
├── agents/
│   ├── refactor-explorer-mini.toml
│   └── refactor-executor-mini.toml
└── config.toml
```

其中 Skill 目录必须包含：

```text
.codex/skills/refactor-orchestrator/SKILL.md
```

## 验证

```bash
bash .codex/skills/refactor-orchestrator/scripts/validate-install.sh
bash .codex/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

## 启动

```bash
codex -m gpt-5.5
```