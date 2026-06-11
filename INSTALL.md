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

- `.agents/skills/refactor-orchestrator`
- `.codex/agents`
- `.codex/config.toml`

如果目标仓库已有 `.codex/config.toml`，脚本会：

1. 创建时间戳备份；
2. 保留已有字段和值；
3. 只补充缺失的 `[agents]` 配置；
4. 在终端显示新增和保留的字段。

## 手动安装

复制以下隐藏目录到目标仓库根目录：

```text
.agents/
.codex/
```

也可以使用可见镜像：

```text
INSTALL_TO_REPOSITORY_ROOT/
├── dot-agents/  → 重命名为 .agents
└── dot-codex/   → 重命名为 .codex
```

## 验证

```bash
bash .agents/skills/refactor-orchestrator/scripts/validate-install.sh
bash .agents/skills/refactor-orchestrator/scripts/runtime-probe.sh
```

## 启动

```bash
codex -m gpt-5.5
```
