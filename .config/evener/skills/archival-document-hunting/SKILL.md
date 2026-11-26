---
name: archival-document-hunting
description: Use when hunting a historical document whose publisher is gone or gated (vendor PDF style guides, manuals, specs, SDK docs), when a known file URL 404s, redirects, or needs a login, when the document may survive only inside an SDK installer, disc image, or web archive, and when packing the results for a researcher with provenance.
---

# Hunting archival documents

## Overview

A document is found when you hold bytes and have read its own title and
edition page. A URL, a filename, a search hit, or a PDF `/Title` is a lead.
Most "it doesn't exist" conclusions are really "I stopped before the
installers and the mirrors".

**Core principle:** attack reservoirs in order of yield, and let every claim
carry its evidence. Never convert an untested reservoir into "not available".

## Order of attack

Work down this ladder. Each rung names the exact command; a rung is only
"exhausted" when you have run it and kept the raw output.

| # | Reservoir | How | Usually yields |
|---|---|---|---|
| 1 | Live vendor URL | `curl -sIL <url>`; then `file` the payload | a redirect chain, rarely bytes |
| 2 | Wayback captures | CDX listing, then replay each capture | redirects and old hostnames |
| 3 | Search engines via text proxy | `r.jina.ai` + Bing/Sogou, exact filename in quotes | mirrors, Scribd, course pages |
| 4 | Internet Archive items | title search, then **item file listings** | SDKs, discs, other people's scans |
| 5 | Vendor SDK installers, disc images | unpack, then grep for the doc | the document itself |
| 6 | Third-party mirrors, fan sites, catalogues | enumerate, don't guess | old scans |
| 7 | Login-gated doc sites | free preview confirms edition; download is an ask | identity proof, not bytes |

**CDX first, not last.** `sw.nokia.com` being DNS-dead does not mean the
captures are; it means the captures are all you have:

```bash
curl -s 'http://web.archive.org/cdx/search/cdx?url=sw.nokia.com/*&output=text&fl=timestamp,original,statuscode,mimetype,length&collapse=urlkey' > cdx.txt
```

Read the `statuscode` column. `200` is a payload; `302` is a pointer. Replay
a pointer with `id_` to see the literal response, then chase the `Location`:

```bash
curl -sI 'https://web.archive.org/web/20060301194359id_/http://sw.nokia.com/id/cbdeebbc-.../Series_40_UI_Style_Guide_v2_1_en.pdf'
```

The hop it names (`forum.nokia.com/dp?id=15015`) is a second address to try
in CDX, on the live host, and against other Nokia CDN names. A 388-byte
capture is a redirect, not a document; never report it as a file size.

**Search engine notes.** Direct Bing serves decoys from this network, and
Google-via-proxy returns 403. `curl -s 'https://r.jina.ai/https://www.bing.com/search?q=%22Series+40+UI+Style+Guide%22+filetype%3Apdf'`
works, Sogou works for a few queries, DDG captchas after a handful. Test one
proxy before writing "search is blocked"; that premise is usually false and
wastes the budget a proxy would have saved.

**The document is usually inside a shipping artifact.** Vendor UI guides
shipped in the SDK, and the SDK is the only surviving copy:

- Internet Archive item pages list files; look for `data1.cab`, `data1.hdr`,
  `data2.cab`, `.iso`, `.zip`.
- InstallShield CABs: `unshield x data1.cab` in a directory that also holds
  `data1.hdr` (it refuses without the header); `cabextract -l` lists.
- A `.zip` that `file` calls ISO 9660 is an ISO: `7z l`, `isoinfo -R -l`,
  then `isoinfo -R -x /PATH/NAME`.
- IBM BookManager books on Softcopy CDs and the OS/2 Online Book Collection
  ISO: `isoinfo -R -x /BOOKS/NAME.BOO > name.boo`.

**Cloudflare in front of a PDF:** let FlareSolverr solve the challenge, take
the returned cookies and the browser user agent, and replay them with
`curl -b cookies.txt -A "$UA" -o file.pdf <url>`. Its own download mode has
returned HTML where the cookie replay returned the PDF. Verify with `file`.

## Verify identity from the pages, not the packaging

- Read page 1 and the edition notice: title as printed, version, date.
- PDF `/Title` and `/CreationDate` are often template leftovers; when they
  disagree with the cover, the cover wins and the disagreement is a finding.
- Compare md5 against a second carrier (mirror, disc image, archive item).
- Check byte size and page count against any published figure. An inferred
  size ("~7 MB" on a listing page) is not a figure.
- Score the result: exact / near / substitute. A near match is a lead, not
  the item; ship it labelled, never as the request.
- Look for truncation: count pages with neither text nor images, then compare
  with the archive's own scan. A PDF ending mid-document still has a valid
  `%PDF-` header.

## Page sets to PDF

1. Copy the pages into a build directory and rewrite every `src` to a path
   that exists there. Print each page once, headless, then concatenate in
   document order.
2. If a referenced figure is missing, insert a visible `MISSING <name>` box
   and add it to the report. Never let the renderer print alt text in place
   of a figure and call the job done.
3. Verify against the sources: hash every image stream in the PDF and match
   it to every source image (perceptual hash for recompressed scans), count
   distinct figures, and grep the text for leftover alt tokens.
4. Say so when pagination differs from the source.

## Delivery and provenance

Keep the first-fetch originals; renders are derived files. Record per file:
source URL, capture timestamp, md5. Include the carriers (ISO, CAB, disc
images) when they are the only original. Never delete scratch until the
originals are inside the shipped package.

`scripts/verify_pdfs.py` checks a directory or a zip against a manifest of
filename, bytes, pages, md5 (and optional blank-page count). It walks
subfolders, so a damaged file parked in `damaged/` cannot escape the manifest.
Build the manifest once with `--write-manifest`, then check the shipped
artifact from a fresh extraction:

```bash
python3 scripts/verify_pdfs.py --zip handoff.zip --manifest manifest.tsv
```

The manifest covers every PDF in the package. When a known-damaged file ships,
list it and run with `--allow-unreadable` so the damage appears in the output
instead of vanishing. A checker that only tests the `%PDF-` header passes a
truncated file; one that checks only bare filenames passes a broken file in a
subfolder. Assert the page count, and run it from a fresh extraction, not the
working tree.

Put `INDEX.md` inside and outside the zip, byte-identical. It states what is
included, what is missing, and which reservoirs are still untested.

## Claim language

- "Found" = bytes in hand, opened, title and edition read.
- "Not found in <N> reservoirs" + the list. Untested reservoirs are named as
  untested, with the next concrete action (log into CSDN, unpack SDK item X).
- Estimates from listing pages are labelled estimates.
- Free-but-login-gated is an actionable ask for the requester. Name the
  item and the site; do not call the document unavailable.

## Red flags

- A 302 capture quoted as a file size.
- A PDF accepted without opening its first page.
- "Search engines are blocked" before trying a text-extraction proxy.
- A checkout, zip, or disc image discarded because it looked empty.
- A render declared complete without counting images in the output.
- A delivery declared ready without a fresh-extraction check.
- A near-match shipped under the requested filename.

## Common mistakes

| Mistake | Fix |
|---|---|
| Searching the web for hours; skipping installers | Search, then SDKs/discs. Installers hold the docs. |
| Treating a 404 on the vendor host as the end | CDX, mirrors, discs. Dead DNS is not dead content. |
| Trusting the filename year or the PDF `/Title` | Read the edition notice; they disagree more often than not. |
| Rendering HTML with unreachable image paths | Rewrite to a build dir; fail loudly on each missing figure. |
| Verifier checks only the header | Hard-code bytes and pages per file; fail unexpected extras. |
| Deleting installers after extracting one file | Keep originals until shipped; re-fetching is the expensive path. |
| Reporting "does not exist" | Report the reservoirs tried, and the untested ones. |

## Testing note

Baselines on this runtime: identity and figure checks pass when the brief
asks for evidence, and fail when it does not. Run the checks even when nobody
asked; put the numbers in the handoff message.
