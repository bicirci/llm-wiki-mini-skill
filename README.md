# llm-wiki-mini

> 面向 Claude Code 和 Codex 的仓库级知识库 skill。只保留离线主线，不安装任何第三方联网提取插件。

## 它做什么

把本地文件和手动整理出的文本编译成持续维护的 wiki。知识只整理一次，之后在本地 markdown 里持续演化。

## 支持范围

- 离线主线：本地 PDF、本地 Markdown/文本/HTML、纯文本粘贴
- 手动入口：网页文章、X/Twitter、微信公众号、YouTube、知乎、小红书

手动入口统一处理为：

- 用户复制正文后直接粘贴
- 或先保存为本地文件，再走主线 ingest

## 仓库级安装

安装不会写入 `~/.claude` 或 `~/.codex`，而是写到当前仓库内。

```bash
# Claude Code
bash install.sh --platform claude

# Codex
bash install.sh --platform codex
```

默认安装位置：

- Claude Code: `.claude/skills/llm-wiki-mini`
- Codex: `.codex/skills/llm-wiki-mini`

旧的 Claude 兼容入口仍保留：

```bash
bash setup.sh
```

## 入口文件

- [CLAUDE.md](CLAUDE.md)：Claude Code 入口
- [AGENTS.md](AGENTS.md)：Codex 入口
- [SKILL.md](SKILL.md)：核心能力和工作流

## 目录结构

```text
你的知识库/
├── raw/
│   ├── articles/
│   ├── tweets/
│   ├── wechat/
│   ├── xiaohongshu/
│   ├── zhihu/
│   ├── pdfs/
│   ├── notes/
│   └── assets/
├── wiki/
│   ├── entities/
│   ├── topics/
│   ├── sources/
│   ├── comparisons/
│   └── synthesis/
├── index.md
├── log.md
└── .wiki-schema.md
```

## FAQ

### 为什么没有自动抓网页、公众号或 YouTube？

这是刻意收缩后的 mini 版。仓库里不再安装任何第三方提取器，也不再依赖浏览器调试端口或额外下载步骤。

### URL 还可以怎么处理？

把正文复制出来直接粘贴，或者先保存成 `.md`、`.txt`、`.html`、`.pdf` 再交给 skill。

### 适合什么场景？

适合要求稳定、可离线、可审计的个人知识库工作流，不适合依赖网页自动抓取的场景。
