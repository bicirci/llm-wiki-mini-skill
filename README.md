# llm-wiki-mini

> A repo-level, offline-first implementation of the `llm-wiki` pattern for Claude Code and Codex.

## What This Is

`llm-wiki-mini` is not a file summarizer and not a query-time RAG wrapper. Its job is to help an agent incrementally build and maintain a persistent wiki that sits between you and your raw sources.

The core idea comes from [Andrej Karpathy's llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and is adapted here as an offline-first repo-level workflow.

- Raw sources are the immutable source of truth.
- The wiki is the maintained knowledge layer.
- The skill instructions are the operating contract that make the agent behave like a disciplined wiki maintainer.

The point is accumulation. When you add a source, the agent should not only summarize it. It should integrate it into the existing wiki, update related pages, strengthen or challenge the current synthesis, and keep the whole knowledge base coherent over time.

## The Three Layers

### 1. Raw Sources

`raw/` stores curated source material. These files are immutable. The agent reads them but does not modify them.

### 2. The Wiki

`wiki/` stores generated knowledge pages: source summaries, entity pages, topic pages, comparisons, and synthesis pages. This is the maintained layer. The agent owns the bookkeeping here.

### 3. The Schema / Skill Contract

The skill instructions define how ingest, query, lint, digest, and graph workflows should behave. In `llm-wiki-mini`, the shared contract lives in `shared/skill-core.md`, and the platform-specific `SKILL.md` files are thin entry points.

## What Mini Changes

Mini only narrows the way sources enter the system. It does not change the core `llm-wiki` philosophy.

What mini keeps:

- Persistent wiki maintenance
- Incremental ingest into existing knowledge
- `index.md` and `log.md` as first-class files
- Query results that can be filed back into the wiki
- Linting for contradictions, gaps, and stale pages

What mini removes:

- Automatic web extraction
- Third-party fetch/extract plugins
- Extra install-time network dependencies

## Input Boundary

- Offline mainline: local PDF, local Markdown/text/HTML, pasted text
- Manual-only inputs: web articles, X/Twitter, WeChat articles, YouTube, Zhihu, Xiaohongshu

Manual-only means:

- copy the text into the chat, or
- save it locally first, then ingest it as a file

## Repo-Level Install

The installer does not write to a global skill location under the user's home directory. It installs into a target directory that you choose.

```bash
# Claude Code
bash install.sh --platform claude

# Codex
bash install.sh --platform codex
```

The installer asks for the target repo directory first. Press Enter to install into the current repository.

Inside the chosen repo, the install paths are:

- Claude Code: `.claude/skills/llm-wiki-mini`
- Codex: `.codex/skills/llm-wiki-mini`

Legacy Claude compatibility entry:

```bash
bash setup.sh
```

## File Roles

- [CLAUDE.md](CLAUDE.md): repo entry for Claude Code
- [AGENTS.md](AGENTS.md): repo entry for Codex
- [references/skill-core.md](references/skill-core.md): shared workflow contract
- [platforms/claude/SKILL.md](platforms/claude/SKILL.md): thin Claude skill entry
- [platforms/codex/SKILL.md](platforms/codex/SKILL.md): thin Codex skill entry

## Why This Works

The expensive part of a knowledge base is not reading. It is maintenance: cross-links, consistency, page updates, synthesis revisions, contradiction tracking, and keeping `index.md` and `log.md` usable as the wiki grows.

Humans usually stop maintaining wikis because the bookkeeping burden compounds. LLMs are good at exactly that bookkeeping. The human curates sources and asks good questions. The agent maintains the wiki.

## FAQ

### Why is this not just a note template?

Because the goal is not to store disconnected notes. The goal is to maintain a growing, structured, interlinked wiki that already contains the accumulated synthesis when you ask the next question.

### Why should query results sometimes be written back into the wiki?

Because a useful comparison, synthesis, or structured answer is part of the knowledge base. If it only lives in chat history, the system loses compounding value.

### Why are `index.md` and `log.md` important?

`index.md` is the content map. `log.md` is the evolution timeline. Together they let the agent navigate the wiki without needing retrieval infrastructure.

### Why no automatic web extraction?

Mini is intentionally offline-first. It reduces operational complexity, removes third-party fetch dependencies, and keeps the source boundary explicit.
