# Project Dictionary

Normative: docs, code identifiers, commit messages, and UI strings use these
terms as defined. Divergences live in Exceptions, nowhere else. Maintained by
the maintaining-documentation skill; `docmaint scan` enforces the
`Use instead of:` lines mechanically.

<!--
Entry format (parsed by docmaint — keep the grammar exact):
  ### term                 — the heading IS the canonical term/replacement
  1–2 sentence definition: what kind of thing + what distinguishes it.
  Distinct from: *neighbor* (one clause on the difference).      [optional]
  Use instead of: syn1, syn2 [manual] (reason).                  [optional]
    - comma-separated plain terms, no markup
    - [manual] = homograph; agents check it in audits, scan skips it
    - one trailing (parenthetical) reason allowed; scan ignores it
Inclusion bar: project-specific, ambiguous, or non-standard usage only.
The dictionary defines; it never explains — link to the owning doc instead.
-->

## Terms

## Names

<!--
Names also state exact spelling/capitalization and a location (path, command,
or upstream URL). scan flags case-variants of the canonical spelling
automatically; list spacing/hyphenation variants in Use instead of:.
-->

## Exceptions

<!--
Format (parsed by docmaint):
  - `term` — `glob`[, `glob`…]; reason, tracking pointer. [temporary|permanent]
Scopes are path globs only — never prose predicates.
[temporary] needs a tracking pointer; scan reports it as a removal candidate
when its globs match nothing (confirm via git log -S before removing).
[permanent] is never flagged; zero current matches doesn't expire it.
-->
