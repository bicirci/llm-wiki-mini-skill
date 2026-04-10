---
name: llm-wiki-mini
description: |
  Compatibility skill entry for the repo-level offline llm-wiki-mini workflow. Use when the user
  wants a persistent wiki maintained from local files or pasted text. Do not use this file as the
  primary installed entry; the installed Claude and Codex skills use platform-specific thin SKILL.md
  files that both point to shared/skill-core.md.
---

# llm-wiki-mini

This repository uses platform-specific thin skill entry files:

- Claude: `platforms/claude/SKILL.md`
- Codex: `platforms/codex/SKILL.md`

The shared workflow reference lives in:

- `references/skill-core.md`

Use that file as the main source of truth for the common `llm-wiki-mini` behavior.
