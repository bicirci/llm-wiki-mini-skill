# llm-wiki-mini Skill Reference

## Purpose

Use this skill to maintain a persistent wiki from local files and pasted text. Do not treat it as a query-time RAG system or a one-off summarizer. The goal is to compile knowledge into a durable markdown wiki that improves over time.

Use it when the user wants to:

- initialize a knowledge wiki
- ingest local files or pasted text into that wiki
- ask questions against the maintained wiki
- generate syntheses, comparisons, or reports from the wiki
- lint the wiki for contradictions, stale claims, or missing structure

Do not use it when the user only wants:

- a one-off summary with no persistent wiki
- automatic web fetching or extractor-plugin behavior
- generic chat unrelated to a maintained knowledge base

## Core Model

There are three layers:

1. `raw/` is the immutable source layer.
2. `wiki/` is the maintained knowledge layer.
3. This skill contract is the operating schema that tells the agent how to maintain the wiki.

Treat the wiki as a compounding artifact. When a new source arrives, integrate it into the existing wiki instead of merely filing an isolated summary.

## Roles

The user is responsible for:

- curating sources
- deciding what matters
- asking follow-up questions
- choosing what to investigate further

The agent is responsible for:

- reading sources
- writing and updating wiki pages
- maintaining cross-links
- updating `index.md`
- appending to `log.md`
- flagging contradictions and stale claims
- strengthening or revising synthesis pages over time

## Inputs

Accepted inputs:

- local PDF files
- local Markdown, text, or HTML files
- pasted text
- manually prepared text copied from a URL source

For URL-like sources, do not attempt automatic extraction. Tell the user to paste the content or save it locally first.

## Workflow

### Init

- Ask for a topic, language, and target wiki path.
- Initialize the wiki structure.
- Ensure `.wiki-schema.md`, `index.md`, `log.md`, and the `wiki/` directories exist.
- Record the wiki path for later sessions when appropriate.

### Ingest

- Determine the source type.
- Preserve the source in the appropriate `raw/` directory.
- Create or update a source summary page in `wiki/sources/`.
- Update related entity pages, topic pages, comparison pages, or synthesis pages when the new source changes the knowledge graph.
- Explicitly note contradictions, corrections, or refinements to prior claims.
- Update `index.md`.
- Append an ingest entry to `log.md`.

Do not reduce ingest to “save file and write one summary.” A useful ingest may touch many existing pages.

### Batch Ingest

- Iterate through supported local files in a directory.
- Reuse the ingest workflow for each source.
- Keep `index.md` and `log.md` consistent across the batch.

### Query

- Read `index.md` first to locate relevant material.
- Read the relevant wiki pages, then answer from the maintained wiki.
- Cite the wiki pages or source summaries used.
- If the answer produces a durable artifact such as a comparison, synthesis, or reusable explanation, file it back into the wiki instead of leaving it only in chat.

### Digest

- Gather the relevant pages and summaries.
- Produce a structured synthesis across multiple pages or sources.
- Write the result to `wiki/synthesis/` when it has lasting value.

### Lint

- Check for contradictions between pages.
- Check for stale claims that newer sources have superseded.
- Check for orphan pages, missing backlinks, and missing concept/entity pages.
- Check for research gaps or areas where the wiki needs more sources.
- Report issues clearly and propose fixes.

### Status

- Summarize source coverage and wiki structure.
- Report the mainline/manual-only source boundary.
- Surface recent activity from `log.md`.
- Highlight obvious weak spots in the current wiki.

### Graph

- Use links across `wiki/` pages to show the current shape of the knowledge base.
- Highlight hubs, orphans, and emerging clusters.

## Output Requirements

When the workflow changes the wiki, keep these files coherent:

- `wiki/sources/` for source summaries
- entity/topic/comparison/synthesis pages as needed
- `index.md`
- `log.md`

Prefer updates that strengthen the whole wiki over isolated page creation.

## Index And Log

Treat `index.md` and `log.md` as first-class files.

- `index.md` is the content map and primary query entrypoint.
- `log.md` is the chronological record of ingests, queries, lint passes, and major changes.

Use stable, grep-friendly log headings when adding new entries.

## Checks Before Finalizing

Before finishing a wiki-maintenance task, verify:

- raw sources were not modified
- the relevant wiki pages were updated, not just the newest summary
- `index.md` reflects the new or changed content
- `log.md` records the operation
- contradictions or stale claims were flagged when present
- valuable query outputs were written back when appropriate

## Bundled Files

- `scripts/source-registry.sh`
- `scripts/adapter-state.sh`
- `scripts/init-wiki.sh`
- `templates/`
