# Documentation Index

<!--
Instantiation: if docs/README.md already exists, merge the fenced table and
the paragraph below INTO it — do not copy this file over it. This standalone
file (as docs/INDEX.md) is only for projects with no docs/README.md.
-->

One row per doc. `Class` is the confirmed evergreen/point-in-time
classification of record (the classify-and-confirm gate's output). `Owns` is
machine-readable: the path globs whose facts this doc owns — `docmaint stale`
diffs them; `—` for point-in-time docs. The fenced table is machine-maintained;
edit rows, never the sentinels.

<!-- doc-index:begin -->
| Doc | What | Class | Owns |
| --- | --- | --- | --- |
| `docs/DICTIONARY.md` | project dictionary (normative terminology) | evergreen | — |
<!-- doc-index:end -->

<!-- Owns `—` = the doc owns no code surface, so `stale` never flags it. Right
for point-in-time rows and for the dictionary (its freshness comes from `scan`
and full audits). An evergreen doc's Owns lists the surfaces whose facts it
owns, scoped tightly — a `docs/**`-style glob just makes the doc flag itself. -->
