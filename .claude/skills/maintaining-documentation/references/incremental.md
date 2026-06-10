# Incremental re-audit (routine, cheap)

Law lives in the hub: rubric, gate, stamping precondition, stamp contract.
**Triage, not soundness** — `stale` narrows the worklist; it never proves a
doc clean. Full audits (references/audit.md) remain the ground-truth pass.

## Preconditions

A doc index with confirmed `Class` values, and stamps from a prior audit.
Missing either → run references/audit.md instead. Never classify by gut here.

## Process

1. Worklist: `docmaint stale`. Reasons mean:
   - `changed: <paths>` — owned ground truth moved; re-verify the doc's
     claims against those paths (verify the verb, not the noun — hub law).
   - `deferred:N` — the last audit left N claims uninterviewed; they stay on
     the list until resolved, regardless of code changes.
   - `unstamped` / `missing` / `stamp-sha-unknown` — not incremental
     material; route to a full audit of that doc.
2. Also run `docmaint scan` — terminology never depends on stamps,
   and a dictionary change since the last run surfaces here.
3. For each worklist doc: re-verify only the affected claims under the hub
   rubric. Auto-fix what's determinate; interview the rest (bounded — defer
   the tail with `--deferred N` honestly recorded).
4. Stamping precondition (hub law): at least one independent verifier
   subagent re-checks the applied edits with citations. Then
   `docmaint stamp --set <doc> [--deferred N]`.
5. Leave everything uncommitted for human review.

## External ground truth

Claims whose truth lives outside this repo (another repo, a vendor binary, a
hosted service) never appear in `stale` output. They are cleared only by full
audits — when reading a doc here, treat such claims as unverified, not stale,
and count them toward `--deferred N` when stamping (hub: stamp contract).
