# CLAUDE.md

这是 `llm-wiki-mini` 在 Claude Code 下的仓库级入口文件。

先看这三个文件：

- [README.md](README.md)：整体说明
- [platforms/claude/CLAUDE.md](platforms/claude/CLAUDE.md)：Claude Code 专属入口提示
- [SKILL.md](SKILL.md)：核心能力和工作流

## Claude 安装动作

优先执行：

```bash
bash install.sh --platform claude
```

兼容旧入口时，也可以执行：

```bash
bash setup.sh
```

默认安装到当前仓库的 `.claude/skills/llm-wiki-mini`。

## 重要提醒

- 这是仓库级 skill，不会写入 `~/.claude/skills`
- mini 版不包含任何第三方联网提取插件
- 安装完成后，再按 [SKILL.md](SKILL.md) 的工作流继续做事
