# AGENTS.md

这是 `llm-wiki-mini` 在 Codex 下的仓库级入口文件。

先看这三个文件：

- [README.md](README.md)：整体说明
- [platforms/codex/AGENTS.md](platforms/codex/AGENTS.md)：Codex 专属入口提示
- [SKILL.md](SKILL.md)：核心能力和工作流

## Codex 安装动作

执行：

```bash
bash install.sh --platform codex
```

默认安装到当前仓库的 `.codex/skills/llm-wiki-mini`。

## 重要提醒

- 这是仓库级 skill，不会写入 `~/.codex/skills`
- mini 版不包含任何第三方联网提取插件
- 安装完成后，再按 [SKILL.md](SKILL.md) 的工作流继续做事

## 使用顺序

1. `init`
2. `ingest`
3. `batch-ingest`
4. `query`
5. `digest`
6. `lint`
7. `status`
8. `graph`
