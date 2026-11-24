# maintaining-documentation — design

**Date:** 2026-06-09
**Status:** approved in discussion (Jesse + Bot); revised after two-agent adversarial review; spec uncommitted by request
**Supersedes:** `auditing-documentation` — its audit process moves into `references/audit.md`, with shared law hoisted into the hub

## Goal

Evolve `auditing-documentation` into `maintaining-documentation`: a skill that keeps a project's documentation healthy over time, not just during big-bang audits. The skill gains a normative **project dictionary**, a maintained **doc index**, a cheap **write-path flow** that updates docs as part of finishing code work, **incremental re-audits**, and **new-doc standards** — all bound by the same invariants the audit skill already enforces, plus a pragmatism law that stops it from generating doc bureaucracy.

## Skill shape

Rename the dotfiles skill directory `auditing-documentation` → `maintaining-documentation`. Deployment is manifest-driven; see Migration. No alias remains.

```
maintaining-documentation/
  SKILL.md                    # hub — shared invariants + dispatch
  references/
    audit.md                  # current Phases 0–4, moved out of SKILL.md
    dictionary.md             # create / seed / extend / revise the dictionary
    write-path.md             # post-change doc maintenance
    incremental.md            # stamp-driven re-audits
    new-docs.md               # creating docs that are born conformant
  templates/
    DICTIONARY-template.md    # skeleton instantiated into target projects
    INDEX-template.md         # doc index skeleton (only for projects with nothing)
  scripts/
    docmaint                  # one helper, subcommands: scan | stamp | stale
```

(The template directory is `templates/`, not `artifacts/`: the dotfiles
`.gitignore` reserves `artifacts/` repo-wide for scratch trees, and colliding
with established repo vocabulary is exactly what this skill polices.)

**SKILL.md (the hub)** keeps only what every flow needs:

- The doc model: docs are claims about reality; evergreen vs. point-in-time; the classify-and-confirm gate (still the one gate never skipped — its confirmed output persists in the index's `class` column).
- The auto-fix rubric, plus its new dictionary clause (see Governance).
- The stamping precondition: no stamp without independent verification of the applied edits. Full audits use two or more competing verifiers (inherited Phase 3); write-path uses at least one independent verifier.
- The shared red-flags and rationalization tables.
- The pragmatism law (below).
- Artifact conventions: the dictionary, the index, and the stamp contract (see Stamps and staleness).
- A dispatch table: which situation you are in → which reference file you MUST read before proceeding. Hard gates, not suggestions.

Everything else moves to `references/`. SKILL.md gets smaller even as the skill grows. The frontmatter description, drafted here so its length and triggers are reviewable (writing-skills rules: trigger conditions only, no workflow summary):

```yaml
description: Use when documentation needs creating, checking, or maintaining —
  docs may have drifted from code, pre-release doc verification, updating docs
  after finishing code work, adding or enforcing project terminology, deciding
  where a new doc should live, or a routine re-audit of previously verified docs.
```

Cross-flow invariants live in SKILL.md only; flows add process, never re-state law. One copy of the law is the skill's own drift prevention. Where hoisting splits a law from the process that used it, `references/audit.md` keeps a forward-reference to the hub — no dangling intra-doc references.

## The pragmatism law

Lives in SKILL.md; binds every flow:

- Docs exist for readers. Before creating any doc, entry, or artifact, name the reader. No reader → don't write it.
- Adopt existing structures before imposing new ones.
- The skill maintains exactly **two** artifacts per project — dictionary and index — plus inline stamps. Never a third metadata file.
- A coverage gap from corpus review is a finding to file, not a mandate to generate a doc.
- The dictionary stays small enough to read in one sitting: load-bearing terms only.
- The write-path flow stays bounded by the diff. If maintenance isn't cheap, it won't happen.

## The dictionary

**Location:** `docs/DICTIONARY.md` in the target project (create `docs/` if absent), instantiated from `templates/DICTIONARY-template.md`. Evergreen: audited, stamped, and the canonical owner of terminology. "Dictionary," not "glossary" — it prescribes usage.

**Structure:** preamble (normative statement + governed scope), `## Terms`, `## Names`, `## Exceptions` at the bottom.

```markdown
# Project Dictionary
Normative: docs, code identifiers, commit messages, and UI strings use
these terms as defined. Divergences live in Exceptions, nowhere else.

## Terms
### box
The isolated, single-tenant execution environment a job runs in.
Distinct from: *runner* (the process that executes jobs inside a box).
Use instead of: VM, instance [manual] (GCP overloads both).

## Names
### credbroker
The credentials broker service. Lowercase, one word. Lives in `services/credbroker/`.
Use instead of: cred-broker, credential broker.

## Exceptions
- `executor` — `internal/sched/**`; dictionary says *runner*; rename pending (#123). [temporary]
- `instance` — `pkg/gcp/**`; upstream vocabulary. [permanent]
```

**Entry rules** (enforced by the template and `references/dictionary.md`):

- Definitions run 1–2 sentences: what kind of thing it is, plus what distinguishes it. The dictionary defines; it never explains. A term needing paragraphs links to the doc that owns the explanation.
- `Distinct from:` disambiguates confusable neighbors — the highest-value line in any entry.
- `Use instead of:` lists deprecated synonyms and makes enforcement mechanical. Grammar, pinned because `docmaint scan` parses it: comma-separated plain terms, no inline markup; an optional trailing parenthetical holds the reason and is ignored by the parser. The entry heading is the replacement.
- A synonym that is also ordinary English (*instance*) can be marked `[manual]`: excluded from mechanical scanning, checked only by agents during audit passes. The escape hatch for homographs is this marker, not a cleverer matcher.
- Names additionally get exact spelling/capitalization and a location (path, command, or upstream URL), which makes them verifiable under the rubric (single live counterpart). Names may carry `Use instead of:` for spacing/hyphenation variants; `scan` flags case-variants of a Name's canonical spelling automatically.
- Inclusion bar: project-specific, ambiguous, or non-standard usage only. No entries for industry-standard terms.

**Governance — full ubiquitous language.** The dictionary governs docs prose, code identifiers, commit messages, and UI strings.

- Prose in evergreen docs: auto-fixable under the rubric's **dictionary clause** — the determinant is the dictionary rather than a code counterpart. Auto-fix fires only when the deprecated synonym maps to exactly one entry (whose heading is the replacement), the match is whole-word, and the replacement leaves the surrounding sentence true. Anything else interviews.
- Code identifiers, UI strings: mismatches are findings, never auto-fixes. Renaming code is a refactor with blast radius. Resolution is one of: rename it / add a dictionary entry / add an exception.
- Commit messages: the dictionary governs future ones; history is never flagged. The only executable hook is write-path, which uses dictionary terms when composing commit messages for the doc edits it ships. Beyond that, commit-message conformance is unenforced — a stated limit, not an oversight.

**Exceptions ledger.** Each entry records the term, where the divergence lives, why, and `[temporary]` (with a tracking pointer) or `[permanent]`. Scopes are path globs — the only scope form `scan` can evaluate; prose predicates ("code touching GCP APIs") are forbidden. Audits skip anything an exception covers. Self-cleaning is conservative: `scan` reports a `[temporary]` exception whose glob matches nothing as a *removal candidate*; removal happens only after git history confirms the divergence was resolved rather than renamed or moved (rubric clause 5 applies to exceptions too). `[permanent]` exceptions are never flagged — zero current matches doesn't expire a deliberate carve-out.

**Bootstrap** (`references/dictionary.md`): where no dictionary exists, mine the corpus and code surfaces for candidates — confusable near-neighbor pairs, recurring project-specific terms, every named component/service/tool — then seed entries through a bounded interview. Load-bearing and ambiguous terms only, not every noun.

## The index

The index absorbs the canonical-owner map *and* the classification record rather than adding new artifacts. One table, one row per doc:

| column | content |
| --- | --- |
| doc | path |
| one-liner | what it is, for readers |
| class | `evergreen` or `point-in-time` — the confirmed classification of record |
| owns | machine-readable pathspecs for the surfaces whose facts this doc owns |

`class` persists the output of the classify-and-confirm gate: confirmed by the human when the index is first built, consulted by every flow afterward. Cold start: a flow that finds no index runs classification (audit Phase 0) first — **no editing flow proceeds without a confirmed classification**. `owns` holds globs, not prose — it is what `docmaint stale` diffs and what write-path maps changed surfaces against; the one-liner is for readers.

If the project has a `docs/README.md`, the index lives there as a sentinel-fenced, machine-maintained table (same idempotent find-and-replace discipline as the stamp); `INDEX-template.md` exists only for projects with nothing. Corpus review (audit Phase 4) consumes and maintains the index instead of re-deriving the owner scheme each run.

## Stamps and staleness

The stamp keeps its inherited format, but its contract changes, and the hub says so explicitly rather than inheriting the old "provenance only, not a scoping key" language: the SHA is provenance **and** the incremental cursor. Incremental re-audits are **triage, not soundness**:

- A stamp recording deferred claims keeps its doc on the incremental worklist regardless of SHA.
- Claims whose ground truth lives outside the repo (another repo, an external binary) are never cleared by `stale`; only a full audit clears them.
- Terminology never depends on stamps: `docmaint scan` sweeps the full governed scope every run, so a dictionary change is caught by the next scan without invalidating any stamp. Stamps cover claim-vs-code drift only.

Full audits remain the soundness pass; incremental exists to make routine runs affordable.

## Flows

Each flow is one lean reference file. All inherit the SKILL.md invariants.

- **`audit.md`** — the current Phases 0–4 move here; shared law hoists to the hub, and intra-doc references are rewritten to point at it. Phase 4 gains the terminology pass (`docmaint scan`) and consumes/maintains the index instead of re-deriving the owner scheme.
- **`incremental.md`** — `docmaint stale` builds the worklist: docs whose `owns` globs changed since their stamp SHA, plus every doc whose stamp records deferred claims. Audit only those claims; verify; restamp. No stamp or no index → full audit.
- **`write-path.md`** — after code work: take the diff, map changed surfaces to owning docs via the index's `owns` globs, fix only the affected claims under the rubric, route new terms to a dictionary interview, then satisfy the stamping precondition (at least one independent verifier re-checks the applied edits) and restamp. Bounded by the diff by construction. Commit messages it composes use dictionary terms.
- **`new-docs.md`** — a decision tree whose first exit is "don't write it." Then: evergreen vs. point-in-time → location and naming → born conformant (dictionary terms, citations on mechanical claims, index row with `class` and `owns`, stamp).
- **`dictionary.md`** — bootstrap, adding/revising/deprecating entries, and the exception lifecycle (add with glob scope; remove only after git-history confirmation).

## Scripts

One single-file helper, `docmaint`, with `--help` and terse output (details to a file, not the terminal):

- `scan` — parse the dictionary's `Use instead of:` lines (pinned grammar; skip `[manual]` synonyms) and the Exceptions globs; sweep git-tracked files minus the inherited exclusions (generated, vendored, `.claude/`, journals) and minus `DICTIONARY.md` itself; match whole-word — case-insensitive for Terms, exact-case for Names plus automatic case-variant flagging; report violations minus exceptions, and zero-match `[temporary]` exceptions as removal candidates. Never auto-edits anything.
- `stamp` — idempotent read/list/write of the last-reviewed sentinel (the never-stack-duplicates logic, made deterministic).
- `stale` — index `owns` globs + stamps → docs whose owned surfaces changed since their stamp SHA (rename-aware diff), plus docs with deferred claims.

Single-file Python 3, stdlib only — it parses markdown lightly, runs git, and globs files; bash would fight all three. Remaining details are plan-level decisions.

## Validation

Light, by explicit decision (Jesse, 2026-06-09): smoke-test the dispatch (each situation reads the right reference) and run the dictionary bootstrap against one real repo to judge output quality. The full writing-skills pressure-scenario battery (RED/GREEN/REFACTOR baselines) is deferred — noted here so nobody mistakes its absence for an oversight.

## Migration

Deployment is owned by homedir-manager: the manifest lists this skill individually by path, and `~/.claude/skills/auditing-documentation` is a deployed symlink pointing into the dotfiles tree. So:

1. Restructure in dotfiles: move the audit process into `references/audit.md`, hoist shared law into the hub, add references, templates, and `docmaint`, rewrite the frontmatter description.
2. `git mv .claude/skills/auditing-documentation .claude/skills/maintaining-documentation`.
3. Update the manifest line `.claude/skills/auditing-documentation` to the new path.
4. Re-deploy per the managing-homedir skill (it owns the symlink lifecycle); verify the old symlink is gone and the new one resolves.
5. No Codex copy exists; nothing else references the old name.

## Non-goals

- No backward-compatibility alias for the old skill name.
- No automation of code renames — the dictionary flags, humans refactor.
- No third per-project metadata artifact, ever.
- No doc generation to satisfy coverage metrics.
- No soundness claim for incremental re-audits — full audits remain the ground-truth pass.
