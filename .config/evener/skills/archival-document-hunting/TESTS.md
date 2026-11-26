# Tests for archival-document-hunting

Method: superpowers:writing-skills. Baseline (no skill) first, then the skill,
then re-test the failing scenario. Every run used a fresh subagent with only the
prompt below.

## S1 — find a document whose vendor host is dead

Prompt: find the Nokia "Series 40 UI Style Guide v2.1" PDF, save it, report URL,
md5, pages, the edition line, and how identity was confirmed. 12 minutes.

**Baseline (no skill):** reached the right neighbourhood on its own — Wayback
CDX showed the v2.1 URL with exactly one capture, HTTP 302, 388 bytes,
`Location: forum.nokia.com/dp?id=15015`; it checked `forum.nokia.com` in CDX
(0 rows), archive.org title search, a mirror listing, archive.today, Memento,
Bing via `r.jina.ai`, DDG, Common Crawl. Result: no bytes, and the verdict
"No bytes anywhere I could reach". The SDK-installer route appeared only under
"next hour". No strong claim of nonexistence, but a strong negative framed by
what it had time to reach.

**With skill:** see "Results" below.

## S2 — identify a document from the file (no skill)

Prompt: which Nokia generation and edition is this file, and what does the
cover say. Baseline read page 1, quoted "Version 1.1; December 8, 2004", and
caught that the PDF `/Title` says "Nokia Series 90" while cover and footers say
"Nokia 7710". Passed without the skill. The identity section is insurance for
the case where the file is being accepted rather than described.

## S3 — render saved pages to PDF, evidence demanded

Two saved pages with three of four image paths unresolvable (`/img/...`,
`../img/...`). Baseline rewrote the paths, rendered with headless Chrome, then
counted images with pypdf and matched pixel md5s to the source PNGs. Passed.

## S4 — render a large page set, no evidence demanded

8 pages, 240 figure references, 238 files on disk (f037 and f112 absent).
Baseline rendered 40 pages, noticed the two missing files, printed visible
placeholder boxes, and reported "238 real figures + 2 gaps" with a per-page
audit. Passed. Failure mode does not reproduce on this runtime at this scale;
the skill keeps the check mandatory rather than relying on noticing.

## S5 — package a handoff (no skill)

16 PDFs, a provenance.tsv with one stale md5, and one PDF truncated to 200 kB.
Baseline found both defects, zipped with CHECKSUMS.txt and INDEX.md, verified
`md5sum -c` from a fresh unzip, and compared every extracted file with `cmp`
against the source. Passed.

## Script tests

`scripts/verify_pdfs.py`:

- `--write-manifest` on the 16-file set: wrote 16 rows, noted the truncated
  file as uninspectable.
- check with that manifest: 1 failure (unreadable truncated PDF), exit 1.
- clean subset of healthy files: 0 failures, exit 0.
- zip mode against a delegate-built handoff: checks inside a fresh extraction.
- Known-damaged but legitimate PDF (CH Series 60 v4.0, upstream-missing
  figures): pages and md5 pass; uninspectable pages are reported as notes, not
  failures.

## Results

**S1 with skill (green):** same 12 minutes, same model. It replayed the 302
with `id_` and read the hop (`forum.nokia.com/dp?id=15015` -> 404), checked the
hop's own captures (403), found a Chinese mirror with a 55-page preview
(HTTP 468 to direct fetch), and reported no bytes while naming untested
reservoirs and two concrete next actions. Baseline had stopped at the 302 and
put installers under "next hour".

**S5 with skill (green):** used the shipped checker, caught the truncated PDF
(the input's planted defect), the stale md5, and that every source_url was
example.invalid. Verified from a fresh extraction (unzip -t, sha256sum -c,
verify_pdfs, cmp of the outside INDEX.md).

**Loophole found in S5:** the agent moved the truncated PDF to `damaged/` and
built the manifest from the top level only, so the original checker reported
`15 entries, 0 failures` with 16 PDFs present. Reproduced, then fixed: the
checker walks subfolders, fails on unreported PDFs anywhere, and refuses an
empty manifest. A known-damaged file is listed and run with
`--allow-unreadable` so it shows as a note.

Checker test matrix after the fix:

| Case | Expect | Got |
|---|---|---|
| Package with unreported `damaged/*.pdf` | fail, EXTRA | fail, exit 1 |
| Same, entry listed + `--allow-unreadable` | pass, note | 0 failures, note |
| Healthy 2-file set | pass | 0 failures |
| Healthy file with one page removed | fail, pages/bytes/md5 | fail, exit 1 |
| Truncated PDF (200 kB of a 1.4 MB file) | fail, unreadable | fail, exit 1 |
| Empty manifest | fail | fail, exit 1 |
| Zip mode on a 62 MB package | same checks, ~1 s | pass/fail as above |
