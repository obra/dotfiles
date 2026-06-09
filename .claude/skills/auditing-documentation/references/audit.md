# Full audit (Phases 0–4)

**Law lives in the hub (SKILL.md):** the classify-and-confirm gate, the
auto-fix rubric (incl. the dictionary clause), scope & exclusions,
verify-the-claim-not-the-symbol, the stamping precondition, red flags, and
rationalizations all bind here and are NOT restated. Read SKILL.md first.

## Process

**0 — Scope, orient, classify (main thread).** Build a **ground-truth map**
first: where CLI defs, routes, config, and core types live (read `CLAUDE.md`'s
package map and the directory layout). Propose the group-level classification;
**confirm with the human**, then persist it: create or update the doc index
(`docs/README.md` fenced table, or `docs/INDEX.md` — see the hub's artifact
conventions) with each doc's `Class` and `Owns` globs. The index is the
classification of record; later flows gate on it instead of re-interviewing.

**1 — Verify.** For **evergreen** docs, fan out one subagent per doc (cap the
width; budget claims per doc). Each extracts atomic claims, classifies per the
rubric, verifies against ground truth — the **code path that enacts each
claim, not just that the named symbol exists** (hub: "Verify the claim, not
just the symbol") — and returns findings **with a `file:line` or
command-output citation for every verdict, including "matches"**. No edits.
**Point-in-time** docs: handle in the main thread (or one batched agent) — no
claim-vs-code checking, only meta-detection (superseded-but-unmarked, missing
date, linked-as-live, broken refs).

**2 — Triage & apply (main thread).** Apply the determinate auto-fixes to the
working tree. Run a **bounded, prioritized** interview on everything else
(evergreen high-confidence-stale first; defer the long tail to the report).
Apply approved point-in-time meta-fixes.

**3 — Adversarially verify your own edits (main thread).** Before declaring
done, **re-check the edits you just applied** — an audit's own fixes are
exactly where confident-but-wrong claims hide: an over-claim, a stale code
*comment* restated as fact, a removal that dropped a still-live concept, an
example that won't validate. Dispatch **two or more competing subagents** that
race to find the largest number of legitimate errors in the applied diff, each
claim re-verified against the code path that *enacts* it (not just symbol
existence) with a `file:line` or command-output citation. Tell them explicitly
they are competing and that **padding or inflating findings disqualifies
them** — that framing is what keeps the pass honest. Fix every confirmed
finding. Only then **stamp the last-reviewed marker** on the verified
evergreen docs (use `docmaint stamp --set <doc> [--deferred N]` — it
is idempotent and records deferred-claim counts), and leave everything
**uncommitted** for human review.

**4 — Corpus review (the whole set, not one doc at a time).** Phases 1–3 are
per-doc, so they are **blind to set-level defects**. When you audit a doc
*set* (not a single file), run a pass over the whole set —
independent/competing agents, fed the doc index (its `Owns` column is the
canonical-owner scheme):

- **Duplication** — the same fact stated substantively in 2+ docs drifts (and
  already has, in practice). Assign each fact a single **canonical owner**
  (HTTP routes → the API doc, CLI flags → the CLI doc, field schemas → the
  schema doc, runtime/firing semantics → the runtime doc, event types → the
  logging doc, …) and replace the copies with cross-references. Fan out **one
  agent per doc** for the trimming — each owns *one file*, so the edits don't
  race.
- **Coverage / gaps** — enumerate the codebase's surfaces (packages, CLI
  commands, routes, event types, config) and check each is documented
  *somewhere*. A missing doc is invisible to a per-doc audit — you only find
  it by listing what *should* exist. File the gaps as findings; write a doc
  only when it has a named reader (hub: pragmatism law; creation goes through
  `references/new-docs.md`).
- **Cross-doc contradictions** — the same fact stated two different ways in
  two docs (one is wrong). Reconcile at the canonical owner.
- **Terminology** — run `docmaint scan` against the repo. Apply the
  rubric's dictionary clause to violations in evergreen prose; everything
  else (code identifiers, UI strings) is a finding → interview (rename / add
  entry / add exception). Zero-match `[temporary]` exceptions are removal
  candidates — confirm via git history (`git log -S`) before removing;
  `[permanent]` exceptions are never touched. New recurring terms with no
  entry → dictionary interview (`references/dictionary.md`).
- **Structure / hygiene** — maintain **the index**: new docs get rows (Class
  + Owns), dead rows go, misfiled point-in-time docs get reclassified via the
  human. Is naming consistent? Is the ordering a fossil (sequential numbers
  implying a frozen, complete scope)?

Per-doc cleanliness is not a healthy set. This phase catches exactly the
class Phases 1–3 cannot.

## Stamping mechanics

Stamp with `docmaint stamp --set <doc> [--deferred N]` — idempotent,
reuses a trailing `---`, never stacks duplicates, fails loudly on a corrupted
stamp block. Record deferred counts honestly: a deferred claim keeps the doc
on the incremental worklist (hub: stamp contract). Stamp only docs you
verified; never stamp point-in-time docs.
