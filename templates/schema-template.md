# Wiki Schema（知识库配置规范）

> 这个文件告诉 AI 如何维护你的知识库。你和 AI 可以一起调整它。

## 知识库信息

- 主题：{{TOPIC}}
- 创建日期：{{DATE}}
- 语言：{{LANGUAGE}}
- 版本：1.1

## 目录结构

```text
{{WIKI_ROOT}}/
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

## Ingest 规则

### 来源边界

| 分类 | 当前来源 | 处理原则 |
|------|----------|----------|
| 离线主线 | `PDF / 本地 PDF`、`Markdown/文本/HTML`、`纯文本粘贴` | 直接进入主线 |
| 手动入口 | `网页文章`、`X/Twitter`、`微信公众号`、`YouTube`、`知乎`、`小红书` | 用户先复制正文，或先保存为本地文件 |

### 素材类型路由

| 来源 | raw 目录 | 处理方式 |
|------|----------|----------|
| 网页文章 | `raw/articles/` | 手动复制正文或保存为本地文件 |
| X/Twitter | `raw/tweets/` | 手动复制正文 |
| 微信公众号 | `raw/wechat/` | 手动复制正文 |
| YouTube | `raw/articles/` | 提供字幕文本或整理后的笔记 |
| 小红书 | `raw/xiaohongshu/` | 手动复制正文 |
| 知乎 | `raw/zhihu/` | 手动复制正文 |
| PDF / 本地 PDF | `raw/pdfs/` | 直接读取 |
| Markdown/文本/HTML | `raw/notes/` | 直接读取 |
| 纯文本粘贴 | `raw/notes/` | 直接使用 |
