# Claude Code 入口

这是 Claude Code 的薄入口文件。共享说明看 [../../README.md](../../README.md)，共享工作流契约看 [../../references/skill-core.md](../../references/skill-core.md)。

执行：

```bash
bash install.sh --platform claude
```

脚本会先询问安装目录；直接回车则使用默认值。

脚本会先询问目标 repo 目录，再自动安装到该 repo 下的 `.claude/skills/llm-wiki-mini`。
