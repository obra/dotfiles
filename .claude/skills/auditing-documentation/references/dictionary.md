# Dictionary work: bootstrap, entries, exceptions

Law lives in the hub: entry grammar, governance scope, the rubric's dictionary
clause, and the pragmatism law all bind here. The template is
`templates/DICTIONARY-template.md`.

## Bootstrap (no dictionary exists)

1. Confirm the reader exists: who needs this dictionary (agents working the
   repo count)? No reader → stop.
2. Mine candidates — three sweeps, breadth-first, no entry-writing yet:
   - **Names:** every component/service/tool/library with a project-specific
     name (directory names, service registries, CLI commands, README nouns).
   - **Confusable pairs:** terms that appear near each other and could be
     conflated (the *box*/*runner* class). These are the highest-value
     entries.
   - **Recurring project terms:** project-specific or non-standard usage that
     repeats across docs/code. Skip industry-standard vocabulary.
3. Interview, bounded: present the candidate list with proposed 1–2 sentence
   definitions in one batch. The human approves/edits/cuts. Load-bearing and
   ambiguous terms only — a dictionary you can read in one sitting.
4. Instantiate `templates/DICTIONARY-template.md` at `docs/DICTIONARY.md`
   (create `docs/` if absent), fill approved entries, add an index row
   (Class: evergreen), and stamp it
   (`scripts/docmaint stamp --set docs/DICTIONARY.md`).
5. Run `scripts/docmaint scan`. Triage per the hub's governance rules; expect
   a first wave of findings — that's the point. Leave fixes uncommitted for
   review.

## Adding / revising an entry

- New term spotted (in review, audit, or conversation): draft the entry
  (definition, Distinct from:, Use instead of:), confirm with the human, add
  in alphabetical order within its section.
- Deprecating a term: move it onto the winner's `Use instead of:` line. If
  live code still uses it, add a `[temporary]` exception with a tracking
  pointer in the same edit — never leave scan red on known divergences.
- A synonym that is ordinary English in prose gets `[manual]` — scan skips
  it; audits check it by hand.

## Exception lifecycle

- **Add:** term + path globs (never prose predicates) + reason +
  `[temporary]` (with tracking pointer) or `[permanent]`.
- **Remove a `[temporary]`:** only after `docmaint scan` reports it as a
  removal candidate AND git history confirms resolution
  (`git log -S '<term>' -- <glob-dir>` shows the rename landed, not that the
  code moved elsewhere). A grep miss alone is not proof — rubric clause 5.
- **`[permanent]`:** never removed on scan evidence. Revisit only when the
  human says the upstream reality changed.

## After any dictionary edit

Re-run `scripts/docmaint scan` (the dictionary governs the whole corpus, so
an edit can create or clear violations anywhere), restamp the dictionary, and
leave everything uncommitted for human review.
