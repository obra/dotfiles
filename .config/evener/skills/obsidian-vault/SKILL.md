---
name: obsidian-vault
description: Use when reading, writing, searching, or navigating Jesse's personal knowledge base (the Obsidian vault at /fast/obsidian), including People files, Daily Notes, Ideas, Concepts, and Granola meeting transcripts; when Jesse mentions his vault, wiki, knowledge base, or obsidian; when checking or running vault sync with ob; or when updating the agent world-note.
---

# Obsidian vault

Jesse's personal knowledge base is an Obsidian vault at `/fast/obsidian` (about 4,900 files), synced to Obsidian Sync ("Jesse's Vault", device name magic-kingdom) by the `ob` CLI (npm package `obsidian-headless`, Obsidian's official headless client). No continuous sync runs: **the vault only syncs when someone runs it.**

## CRITICAL: sync before reading, sync after writing

```bash
ob sync --path /fast/obsidian           # pull + push in one shot
ob sync-status --path /fast/obsidian    # prints the sync configuration only
```

Run `ob sync` before reading vault content (his other devices push changes) and after every write (or your edits stay stuck locally). `ob sync` is also the freshness check: a current vault finishes in seconds and prints "Fully synced" to stdout. `ob sync-status` prints configuration only, with no pending-changes or last-sync lines. A no-op run writes no completion line to sync.log; errors do get logged, so grep the log for errors rather than completions. `ob sync --continuous` exists; only run it detached if Jesse asks. Syncing needs write access to the vault: in a sandboxed read-only session the lock fails with "Another sync instance is already running", so read-only delegates should leave `ob sync` to the main session.

Sync state lives in `~/.config/obsidian-headless/sync/2d8c0424a48041b5188668300b1d316e/`: config.json (holds an encryption key, never print it), sync.log (run history), state.db (internals; never hand-query it, `ob sync-status` and the log answer status questions).

## Vault map

Some folders (Personal, Ideas, AI Agents) have README.md indexes: read the folder's README first when present, and update it when adding notes. Others, like Daily Notes, have none.

| Folder | What |
|---|---|
| Personal/ | health, family, finance, travel, home notes, indexed in its README |
| People/ | one note per person (`<name>.md`, type: person, ## Context + ## Mentions) |
| Ideas/ | idea index by status (Active, Built, Shelved, Brainstorm); README is the master index |
| AI Agents/ | agent-development research plus agent artifacts ([[Dear diary]], [[Jesse's World]]) |
| Concepts/ | concept notes |
| Daily Notes/ | YYYY-MM-DD.md with ## Meetings linking Granola notes; the trail ends 2026-07-24 |
| Deletion Candidates/ | staging area for cleanup; daily notes 2026-01-05 through 2026-07-24 were moved here, so check this folder for date-named notes too |
| Granola/ | meeting transcripts and summaries (Transcripts/, Summaries/, about 200) |
| Ghost Pepper Meetings/ | dated meeting folders |
| Chats/ | chat summaries |
| docs/superpowers/ | superpowers docs |
| keyboardio/, RTIR/, VaccinateCA/, Photography/, recipes/ | project and topic folders |
| attachments/, i/ | images and loose files |

## Conventions

- YAML front matter: title, date, type (concept, idea, person, meeting), status (seedling, active, built, reference), tags, and related/source as wiki-links. Match the surrounding notes.
- Notes interlink heavily with [[wiki-links]]; link People and Concepts when you create notes.
- The local `.obsidian/` directory is empty because config syncing is disabled. Never edit it.
- About 32 legacy server-only files are not mirrored locally (skipped by the sync type filter). That is deliberate; do not try to fix it.

## World-note

`AI Agents/Jesse's World.md` is the agent-maintained context note: who Jesse is, his projects, preferences, infrastructure, and sync health. Read it early when working in the vault. When you learn something durable, add it there, then run `ob sync`.
