# Write-path: docs ride along with code changes

Law lives in the hub. This flow is **bounded by the diff by construction** —
if it stops being cheap, it stops happening. Run it when finishing code work,
before requesting review.

## Preconditions

A doc index with confirmed `Class` values. None → offer to run
references/audit.md Phase 0 first (one-time cost); do NOT edit docs against
an unconfirmed classification.

## Process

1. Get the change surface: `git diff --name-only -M <base>...HEAD` (plus
   uncommitted changes if relevant).
2. Map changed paths against the index's `Owns` globs → the owning evergreen
   docs. No owner for a surface that plainly needs documenting → note it as
   a finding; do not invent a doc (pragmatism law: name the reader first).
3. For each owning doc, re-verify only the claims the diff touches, under
   the hub rubric: auto-fix determinate drift; collect the rest for the
   human as part of the change's review notes. Never edit point-in-time
   docs.
4. New terms: if the change introduces a recurring term or renames a
   concept, route to references/dictionary.md (entry or exception — e.g. a
   rename in flight gets a `[temporary]` exception in the same change).
5. Run `docmaint scan`; fix violations your change introduced.
6. Stamping precondition (hub law): at least one independent verifier
   subagent re-checks the applied doc edits with citations. Then
   `docmaint stamp --set <doc>` for each verified doc.
7. The doc edits join the change's commits. Write commit messages with
   dictionary terms — `scan` does not check messages, so this manual
   convention is the only commit-message hook there is; history is never
   rewritten.
