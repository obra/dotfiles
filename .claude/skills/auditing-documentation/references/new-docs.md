# New docs: born conformant

Law lives in the hub. First exit wins:

1. **Don't write it.** Name the reader. If no specific human or agent needs
   this doc, stop — file a note instead. A coverage gap is a finding, not a
   mandate (pragmatism law).
2. **Classify before creating** — the doc's contract, not its folder:
   - Records a decision/design/plan as of now → **point-in-time**: dated
     filename (`YYYY-MM-DD-<topic>.md`), under the project's specs/plans
     dir, never stamped, index row with Class `point-in-time`, Owns `—`.
   - Describes current reality and must track it → **evergreen**: undated
     name, lives with the evergreen docs, and continues below.
3. **Evergreen birth checklist:**
   - Terms conform to `docs/DICTIONARY.md`; new recurring terms go through
     references/dictionary.md in the same change.
   - Mechanical claims (paths, flags, routes, config) carry verifiable
     citations — written against the code path that enacts them (verify the
     verb — hub law).
   - Add the index row: one-liner for readers, Class `evergreen`, `Owns`
     globs for the surfaces whose facts it owns (machine-readable —
     `docmaint stale` will diff them).
   - Run `docmaint scan`; fix what the new doc introduced.
   - Verify, then stamp: `docmaint stamp --set <doc>` (stamping
     precondition applies — an independent verifier re-checks before the
     stamp).
4. **Don't duplicate.** If the fact already has a canonical owner, link to
   it; the new doc owns only what nothing else owns (one fact, one owner).
