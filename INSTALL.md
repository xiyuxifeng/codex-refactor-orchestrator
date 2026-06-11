# Installation

## 推荐：安装脚本

```bash
./install.sh /path/to/your/repository
```

脚本会安装：

- `.agents/skills/refactor-orchestrator`
- `.codex/agents`
- `.codex/config.toml`（仅当目标仓库不存在该文件时）

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
```

## 启动

```bash
codex -m gpt-5.5
```
