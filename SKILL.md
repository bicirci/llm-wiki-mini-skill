---
name: llm-wiki-mini
description: |
  仓库级个人知识库构建 skill。支持 Claude Code 和 Codex；只保留离线主线：
  本地 PDF、本地 Markdown/文本/HTML、纯文本粘贴。网页、公众号、YouTube、
  X/Twitter、知乎、小红书统一走手动入口。
---

# llm-wiki-mini

## 核心定位

- 这是离线优先的 mini 版 skill
- 支持 Claude Code 和 Codex
- 安装到当前仓库内，而不是用户主目录
- 不安装任何第三方联网提取插件

## Script Directory

Scripts 位于 `scripts/` 目录。

1. `SKILL_DIR` = 当前 `SKILL.md` 所在目录
2. 脚本路径 = `${SKILL_DIR}/scripts/<script-name>`

## 依赖检查

这个 mini skill 没有第三方提取器前置依赖。

## 来源边界

```bash
bash ${SKILL_DIR}/scripts/source-registry.sh list
```

- `core_builtin`：直接进入主线
- `manual_only`：不自动提取，提示用户手动提供内容

状态检查统一走：

```bash
bash ${SKILL_DIR}/scripts/adapter-state.sh check <source_id>
```

## 工作流路由

| 用户意图关键词 | 工作流 |
|---|---|
| 初始化知识库、新建 wiki、创建知识库 | `init` |
| 给链接、文件路径、添加素材、消化、整理 | `ingest` |
| 批量消化、整理一个文件夹 | `batch-ingest` |
| 关于 XX、查询、总结一下 | `query` |
| 深度分析、综述、digest XX | `digest` |
| 健康检查、lint | `lint` |
| 知识库状态 | `status` |
| graph、知识图谱 | `graph` |

## init

执行：

```bash
bash ${SKILL_DIR}/scripts/init-wiki.sh "<路径>" "<主题>" "<语言>"
```

## ingest

- URL：
  - 先运行 `bash ${SKILL_DIR}/scripts/source-registry.sh match-url "<url>"`
  - 再运行 `bash ${SKILL_DIR}/scripts/adapter-state.sh check <source_id>`
  - mini 版对 URL 一律不自动提取，直接提示用户复制正文，或先保存为本地文件
- 本地文件：
  - 运行 `bash ${SKILL_DIR}/scripts/source-registry.sh match-file "<path>"`
  - 对 `local_pdf` 和 `local_document` 直接进入主线
- 纯文本粘贴：
  - 运行 `bash ${SKILL_DIR}/scripts/source-registry.sh get plain_text`
  - 直接进入主线

主线处理：

1. 把原始素材保存到对应 `raw/` 目录
2. 生成 `wiki/sources/` 摘要页
3. 提取关键概念，更新或创建实体页和主题页
4. 更新 `index.md`、`log.md`

## batch-ingest

遍历目录下的 `.pdf`、`.md`、`.txt`、`.html`，对每个文件复用 `ingest` 主线。

## query

1. 先读 `index.md`
2. 在 `wiki/` 下搜索关键词
3. 阅读相关页面并回答

## digest

收集相关页面和素材摘要，整理为结构化综合报告，必要时写回 `wiki/synthesis/`。

## lint

检查孤立页面、断链、缺失概念页，以及 `index.md` 与实际文件的一致性。

## status

1. 运行 `bash ${SKILL_DIR}/scripts/source-registry.sh list`
2. 汇总各类 `raw/` 素材数量
3. 运行 `bash ${SKILL_DIR}/scripts/adapter-state.sh summary-human`

## graph

从 `wiki/` 页面提取 `[[链接]]`，输出文本版知识地图或 Mermaid 图。
