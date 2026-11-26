#!/usr/bin/env python3
"""Check a delivery of PDFs against a manifest, ideally straight from the shipped zip.

The manifest is the truth you established earlier, when you had the sources in
front of you. This script is what catches later damage: a re-render that
dropped pages, a truncated download, a swapped or edited file, a stray extra.

    verify_pdfs.py DIR --manifest MANIFEST.tsv
    verify_pdfs.py --zip DELIVERY.zip --manifest MANIFEST.tsv
    verify_pdfs.py DIR --write-manifest MANIFEST.tsv      # first-time baseline

Manifest is TSV with a header row. Required columns: `filename`, `bytes`,
`pages`, `md5`. Optional `blank` column: the number of legitimately blank
pages (no text, no images), so future re-renders cannot quietly lose more.
Extra columns are ignored.

Exit 0 only when every check passes. A file whose header says %PDF- but which
will not open is a failure, not a pass; so is one that opens but has the wrong
page count. Pages that raise while being inspected are reported, not fatal.
"""
import argparse
import contextlib
import hashlib
import io
import logging
import os
import shutil
import sys
import tempfile
import zipfile

from pypdf import PdfReader

logging.getLogger("pypdf").setLevel(logging.ERROR)


@contextlib.contextmanager
def quiet_pdf():
    """pypdf prints parser noise straight to stdout; keep our report readable."""
    sink = io.StringIO()
    with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
        yield sink


def md5(path, chunk=1 << 20):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def inspect_pdf(path, want_blanks=True):
    """Return (pages, blanks, damaged_pages, error). Blanks = no text, no images."""
    with quiet_pdf():
        try:
            reader = PdfReader(path)
            pages = len(reader.pages)
        except Exception as exc:
            return None, [], [], f"{type(exc).__name__}: {exc}"
        if not want_blanks:
            return pages, [], [], None
        blanks, damaged = [], []
        for i in range(pages):
            try:
                page = reader.pages[i]
                text = (page.extract_text() or "").strip()
                has_image = bool(page.images)
            except Exception:
                damaged.append(i + 1)
                continue
            if not text and not has_image:
                blanks.append(i + 1)
    return pages, blanks, damaged, None


def load_manifest(path):
    with open(path, encoding="utf-8") as f:
        header = f.readline().rstrip("\n").split("\t")
        need = {"filename", "bytes", "pages", "md5"}
        missing = need - set(header)
        if missing:
            sys.exit(f"manifest {path} lacks columns: {', '.join(sorted(missing))}")
        return [
            dict(zip(header, line.rstrip("\n").split("\t")))
            for line in f
            if line.strip() and not line.startswith("#")
        ]


def pdfs_in(root):
    """Relative paths of every PDF under root, subfolders included."""
    out = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            if name.lower().endswith(".pdf"):
                out.append(os.path.relpath(os.path.join(dirpath, name), root))
    return sorted(out)


def write_manifest(root, path):
    rows = [("filename", "bytes", "pages", "md5", "blank")]
    for name in pdfs_in(root):
        full = os.path.join(root, name)
        pages, blanks, damaged, err = inspect_pdf(full)
        if err:
            print(f"NOTE {name}: cannot inspect ({err}); pages column is 0", file=sys.stderr)
            pages, blanks = 0, []
        rows.append((name, str(os.path.getsize(full)), str(pages), md5(full), str(len(blanks))))
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join("\t".join(r) for r in rows) + "\n")
    print(f"wrote {path}: {len(rows) - 1} entries")


def check_dir(root, rows, allow_unreadable=False):
    failures, notes = [], []
    found = pdfs_in(root)
    by_name = {os.path.basename(r["filename"]): r for r in rows}
    by_rel = {os.path.normpath(r["filename"]): r for r in rows}
    covered = set()
    for rel in found:
        rel_n = os.path.normpath(rel)
        row = by_rel.get(rel_n) or by_name.get(os.path.basename(rel))
        if row is None:
            failures.append(f"unexpected file not in manifest: {rel}")
            notes.append(f"{rel}: EXTRA")
        else:
            covered.add(id(row))
    for r in rows:
        name = r["filename"]
        path = os.path.join(root, name)
        if not os.path.isfile(path) and os.path.basename(name) in {os.path.basename(f) for f in found}:
            path = os.path.join(root, next(f for f in found if os.path.basename(f) == os.path.basename(name)))
        if not os.path.isfile(path):
            failures.append(f"missing: {name}")
            notes.append(f"{name}: MISSING")
            continue
        problems = []
        got_bytes = os.path.getsize(path)
        if str(got_bytes) != r["bytes"]:
            problems.append(f"bytes {got_bytes} != {r['bytes']}")
        got_md5 = md5(path)
        if got_md5 != r["md5"]:
            problems.append(f"md5 {got_md5} != {r['md5']}")
        want_blanks = r.get("blank", "") not in ("", None)
        pages, blanks, damaged, err = inspect_pdf(path, want_blanks=want_blanks)
        if err:
            if allow_unreadable:
                notes.append(f"{name}: UNREADABLE (allowed) {err}")
            else:
                failures.append(f"unreadable PDF: {name} ({err})")
                notes.append(f"{name}: UNREADABLE")
            continue
        if str(pages) != r["pages"]:
            problems.append(f"pages {pages} != {r['pages']}")
        want_blank = r.get("blank", "")
        if want_blank not in ("", None) and str(len(blanks)) != want_blank:
            problems.append(f"blank pages {len(blanks)} != {want_blank}")
        elif want_blank in ("", None) and blanks:
            notes.append(f"{name}: {len(blanks)} blank page(s) {blanks}")
        if damaged:
            notes.append(f"{name}: {len(damaged)} uninspectable page(s) {damaged}")
        if problems:
            failures.append(f"{name}: " + "; ".join(problems))
            notes.append(f"{name}: BAD")
        elif not damaged:
            notes.append(f"{name}: ok")
    return failures, notes


def check_zip(zip_path, rows, allow_unreadable=False):
    tmp = tempfile.mkdtemp(prefix="verify-")
    try:
        with zipfile.ZipFile(zip_path) as z:
            bad = z.testzip()
            if bad:
                return [f"zip member corrupt: {bad}"], []
            for info in z.infolist():
                if info.filename.startswith("/") or ".." in info.filename.split("/"):
                    return [f"unsafe zip path: {info.filename}"], []
            z.extractall(tmp)
        return check_dir(tmp, rows, allow_unreadable)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("dir", nargs="?", help="directory of PDFs to check")
    ap.add_argument("--zip", help="check a zip by extracting it to a fresh temp dir first")
    ap.add_argument("--manifest", help="TSV manifest (see docstring)")
    ap.add_argument("--write-manifest", help="write a baseline manifest from DIR, then exit")
    ap.add_argument("--allow-empty", action="store_true",
                    help="permit a manifest with no entries (an empty pass by default is a bug)")
    ap.add_argument("--allow-unreadable", action="store_true",
                    help="report unreadable PDFs listed in the manifest as notes, not failures")
    ap.add_argument("--verbose", action="store_true", help="print a line for every file")
    a = ap.parse_args()
    if a.write_manifest:
        if not a.dir:
            sys.exit("--write-manifest needs DIR")
        return write_manifest(a.dir, a.write_manifest)
    if not a.manifest:
        sys.exit("pass --manifest (or --write-manifest to create one)")
    if bool(a.dir) == bool(a.zip):
        sys.exit("pass exactly one of DIR or --zip")
    rows = load_manifest(a.manifest)
    if not rows and not a.allow_empty:
        sys.exit(f"manifest {a.manifest} has no entries; refusing to pass an empty delivery")
    failures, notes = (check_zip(a.zip, rows, a.allow_unreadable) if a.zip
                       else check_dir(a.dir, rows, a.allow_unreadable))
    if a.verbose:
        print("\n".join(notes))
    for f in failures:
        print(f"FAIL {f}", file=sys.stderr)
    print(f"{len(rows)} manifest entries, {len(failures)} failure(s)")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
