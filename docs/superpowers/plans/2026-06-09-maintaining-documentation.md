# maintaining-documentation Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the `auditing-documentation` skill into `maintaining-documentation` per the approved spec at `docs/superpowers/specs/2026-06-09-maintaining-documentation-design.md` — hub SKILL.md, five reference flows, two artifact templates, and a `docmaint` helper script.

**Architecture:** Hub-and-spokes skill: SKILL.md holds cross-flow law (doc model, rubric, stamping precondition, pragmatism law, dispatch); `references/` holds one file per flow; `templates/` holds templates instantiated into target projects; `scripts/docmaint` (Python 3 stdlib, TDD'd) does the mechanical work (scan/stamp/stale). Build everything under the existing directory name first; rename + manifest + redeploy last.

**Tech Stack:** Markdown skill files; Python 3 stdlib (`argparse`, `re`, `subprocess`, `pathlib`, `tempfile`, `unittest`); git; homedir-manager for deployment.

**Repo:** ALL work happens in `/Users/jesse/git/dotfiles`. The repo has unrelated uncommitted changes (`.claude/skills/roborev-*`, `.codex/skills/roborev-*`, `.zshenv`) — NEVER touch them, NEVER `git add -A`. Always `git add` explicit paths. The spec and this plan stay uncommitted by Jesse's request.

**Source of truth being restructured:** `.claude/skills/auditing-documentation/SKILL.md` (referred to below as OLD). Read it fully before Task 8.

---

### Task 1: Branch and scaffolding

**Files:**
- Create: `.claude/skills/auditing-documentation/references/` (dir)
- Create: `.claude/skills/auditing-documentation/templates/` (dir)
- Create: `.claude/skills/auditing-documentation/scripts/` (dir)

- [ ] **Step 1: Create the working branch**

```bash
cd /Users/jesse/git/dotfiles
git status --short   # expect only roborev-*/.zshenv modifications — leave them alone
git checkout -b maintaining-documentation-skill
```

- [ ] **Step 2: Create directories**

```bash
mkdir -p .claude/skills/auditing-documentation/references \
         .claude/skills/auditing-documentation/templates \
         .claude/skills/auditing-documentation/scripts
```

No commit yet (empty dirs aren't tracked); they ride with Task 2.

---

### Task 2: docmaint scaffold + CLI

**Files:**
- Create: `.claude/skills/auditing-documentation/scripts/docmaint`
- Create: `.claude/skills/auditing-documentation/scripts/docmaint_test.py`

- [ ] **Step 1: Write the failing test**

Create `scripts/docmaint_test.py`:

```python
#!/usr/bin/env python3
"""Tests for docmaint. Run directly: python3 docmaint_test.py"""
import importlib.machinery
import importlib.util
import pathlib
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent

# docmaint has no .py extension; load it by path.
_loader = importlib.machinery.SourceFileLoader("docmaint", str(HERE / "docmaint"))
_spec = importlib.util.spec_from_loader("docmaint", _loader)
docmaint = importlib.util.module_from_spec(_spec)
_loader.exec_module(docmaint)


class TestCli(unittest.TestCase):
    def test_help_exits_zero_and_names_subcommands(self):
        proc = subprocess.run(
            [sys.executable, str(HERE / "docmaint"), "--help"],
            capture_output=True, text=True,
        )
        self.assertEqual(proc.returncode, 0)
        for sub in ("scan", "stamp", "stale"):
            self.assertIn(sub, proc.stdout)


if __name__ == "__main__":
    result = unittest.main(exit=False).result
    failed = len(result.failures) + len(result.errors)
    print(f"RESULT run={result.testsRun} failed={failed}")
    sys.exit(1 if failed else 0)
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/jesse/git/dotfiles/.claude/skills/auditing-documentation
python3 scripts/docmaint_test.py
```

Expected: FAIL — `FileNotFoundError` loading `docmaint` (file doesn't exist).

- [ ] **Step 3: Write the scaffold**

Create `scripts/docmaint`:

```python
#!/usr/bin/env python3
"""docmaint — mechanical helpers for the maintaining-documentation skill.

Subcommands:
  scan   sweep git-tracked files for deprecated terms per docs/DICTIONARY.md;
         exit 1 if violations found
  stamp  list or set last-reviewed stamps on evergreen docs
  stale  list docs whose owned surfaces changed since their stamp SHA,
         plus docs with deferred claims or no stamp

Output is terse; scan writes its full report to a temp file and prints the path.
Stdlib only. Run from anywhere; --root points at the target repo (default: cwd).
"""
import argparse
import datetime
import re
import subprocess
import sys
import tempfile
from pathlib import Path

DICT_RELPATH = Path("docs/DICTIONARY.md")
STAMP_SENTINEL = "<!-- doc-audit:last-reviewed -->"
INDEX_BEGIN = "<!-- doc-index:begin -->"
INDEX_END = "<!-- doc-index:end -->"
SWEEP_EXCLUDE_PREFIXES = (".claude/", ".private-journal/")
GENERATED_MARKERS = ("generated by", "do not edit")


def git(root: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *args],
        capture_output=True, text=True, check=True,
    ).stdout


def cmd_scan(args: argparse.Namespace) -> int:
    raise NotImplementedError


def cmd_stamp(args: argparse.Namespace) -> int:
    raise NotImplementedError


def cmd_stale(args: argparse.Namespace) -> int:
    raise NotImplementedError


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="docmaint",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = p.add_subparsers(dest="command", required=True)

    s = sub.add_parser("scan", help="sweep for deprecated terms; exit 1 on violations")
    s.add_argument("--root", type=Path, default=Path("."), help="target repo root")
    s.set_defaults(func=cmd_scan)

    s = sub.add_parser("stamp", help="list or set last-reviewed stamps")
    s.add_argument("--root", type=Path, default=Path("."), help="target repo root")
    s.add_argument("--list", action="store_true", help="list all stamps")
    s.add_argument("--set", metavar="DOC", help="set/refresh the stamp on DOC")
    s.add_argument("--deferred", type=int, default=0,
                   help="claims deferred to review (recorded in the stamp)")
    s.set_defaults(func=cmd_stamp)

    s = sub.add_parser("stale", help="list docs needing incremental re-audit")
    s.add_argument("--root", type=Path, default=Path("."), help="target repo root")
    s.set_defaults(func=cmd_stale)
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
```

```bash
chmod +x scripts/docmaint
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
python3 scripts/docmaint_test.py
```

Expected: `RESULT run=1 failed=0`, exit 0.

- [ ] **Step 5: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/scripts/docmaint \
        .claude/skills/auditing-documentation/scripts/docmaint_test.py
git commit -m "skill(maintaining-documentation): docmaint scaffold with scan/stamp/stale CLI"
```

---

### Task 3: docmaint dictionary parser

**Files:**
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint` (replace the `cmd_scan` stub area with parsing functions; `cmd_scan` itself stays stubbed until Task 4)
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint_test.py` (add tests)

The grammar being parsed (normative, from the spec):
- Sections `## Terms`, `## Names`, `## Exceptions`; entries are `### <heading>`.
- `Use instead of:` line: comma-separated plain terms, no markup; a synonym may carry a trailing `[manual]` marker; an optional trailing parenthetical holds the reason and is ignored; optional trailing period.
- Exception bullet: `` - `term` — `glob`[, `glob`…]; free text. [temporary] `` or `[permanent]`.

- [ ] **Step 1: Add failing tests**

Add to `docmaint_test.py`:

```python
FIXTURE_DICT = """\
# Project Dictionary
Normative: docs, code identifiers, commit messages, and UI strings use
these terms as defined. Divergences live in Exceptions, nowhere else.

## Terms
### box
The isolated, single-tenant execution environment a job runs in.
Distinct from: *runner* (the process that executes jobs inside a box).
Use instead of: VM, instance [manual] (GCP overloads both).

### runner
The process that executes jobs inside a box.
Use instead of: executor.

## Names
### credbroker
The credentials broker service. Lowercase, one word. Lives in `services/credbroker/`.
Use instead of: cred-broker, credential broker.

## Exceptions
- `executor` — `internal/sched/**`; dictionary says *runner*; rename pending (#123). [temporary]
- `instance` — `pkg/gcp/**`; upstream vocabulary. [permanent]
"""


class TestParseDictionary(unittest.TestCase):
    def setUp(self):
        self.d = docmaint.parse_dictionary(FIXTURE_DICT)

    def test_terms_and_names_sections(self):
        self.assertEqual([e.name for e in self.d.entries if e.section == "Terms"],
                         ["box", "runner"])
        self.assertEqual([e.name for e in self.d.entries if e.section == "Names"],
                         ["credbroker"])

    def test_synonyms_with_manual_marker_and_parenthetical_stripped(self):
        box = next(e for e in self.d.entries if e.name == "box")
        self.assertEqual(box.synonyms, [("VM", False), ("instance", True)])

    def test_multiword_synonym(self):
        cb = next(e for e in self.d.entries if e.name == "credbroker")
        self.assertEqual(cb.synonyms, [("cred-broker", False), ("credential broker", False)])

    def test_exceptions(self):
        self.assertEqual(len(self.d.exceptions), 2)
        ex0, ex1 = self.d.exceptions
        self.assertEqual((ex0.term, ex0.globs, ex0.status),
                         ("executor", ["internal/sched/**"], "temporary"))
        self.assertEqual((ex1.term, ex1.globs, ex1.status),
                         ("instance", ["pkg/gcp/**"], "permanent"))

    def test_entry_without_use_instead_of_has_no_synonyms(self):
        text = "## Terms\n### plain\nA thing.\n"
        d = docmaint.parse_dictionary(text)
        self.assertEqual(d.entries[0].synonyms, [])
```

- [ ] **Step 2: Run to verify they fail**

```bash
python3 scripts/docmaint_test.py
```

Expected: FAIL — `AttributeError: module 'docmaint' has no attribute 'parse_dictionary'`.

- [ ] **Step 3: Implement the parser**

Insert into `docmaint` after the `git()` function (before `cmd_scan`):

```python
class Entry:
    def __init__(self, name: str, section: str):
        self.name = name
        self.section = section          # "Terms" or "Names"
        self.synonyms: list[tuple[str, bool]] = []   # (text, is_manual)


class Exception_:
    def __init__(self, term: str, globs: list[str], status: str):
        self.term = term
        self.globs = globs
        self.status = status            # "temporary" or "permanent"


class Dictionary:
    def __init__(self):
        self.entries: list[Entry] = []
        self.exceptions: list[Exception_] = []


USE_INSTEAD_RE = re.compile(r"^Use instead of:\s*(.+?)\s*$")
EXCEPTION_RE = re.compile(
    r"^- `(?P<term>[^`]+)` — (?P<globs>`[^`]+`(?:, `[^`]+`)*);"
    r".*\[(?P<status>temporary|permanent)\]\s*$"
)


def _parse_synonyms(raw: str) -> list[tuple[str, bool]]:
    # Strip one trailing parenthetical (the human-readable reason), then a period.
    raw = re.sub(r"\s*\([^()]*\)\s*\.?\s*$", "", raw).rstrip(". ")
    out = []
    for piece in raw.split(","):
        piece = piece.strip()
        if not piece:
            continue
        manual = piece.endswith("[manual]")
        if manual:
            piece = piece[: -len("[manual]")].strip()
        out.append((piece, manual))
    return out


def parse_dictionary(text: str) -> Dictionary:
    d = Dictionary()
    section = None
    entry = None
    for line in text.splitlines():
        if line.startswith("## "):
            section = line[3:].strip()
            entry = None
            continue
        if line.startswith("### ") and section in ("Terms", "Names"):
            entry = Entry(line[4:].strip(), section)
            d.entries.append(entry)
            continue
        if section == "Exceptions":
            m = EXCEPTION_RE.match(line)
            if m:
                globs = [g.strip("` ") for g in m.group("globs").split(",")]
                d.exceptions.append(Exception_(m.group("term"), globs, m.group("status")))
            continue
        if entry is not None:
            m = USE_INSTEAD_RE.match(line)
            if m:
                entry.synonyms = _parse_synonyms(m.group(1))
    return d
```

- [ ] **Step 4: Run the tests, verify all pass**

```bash
python3 scripts/docmaint_test.py
```

Expected: `RESULT run=6 failed=0`.

- [ ] **Step 5: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/scripts/docmaint \
        .claude/skills/auditing-documentation/scripts/docmaint_test.py
git commit -m "skill(maintaining-documentation): docmaint dictionary parser (pinned grammar)"
```

---

### Task 4: docmaint scan

**Files:**
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint` (add `glob_match`, sweep helpers; implement `cmd_scan`)
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint_test.py` (add tests)

Behavior (from spec): sweep git-tracked files minus exclusions (`.claude/`, `.private-journal/`, generated/do-not-edit files, `docs/DICTIONARY.md` itself); whole-word matches; Terms case-insensitive, `[manual]` skipped; Names exact-case plus automatic case-variant flagging; suppress hits covered by an exception glob for that term; report zero-match `[temporary]` exceptions as removal candidates; never edit anything; exit 1 if violations.

- [ ] **Step 1: Add failing tests**

Add to `docmaint_test.py`:

```python
def make_repo(tmp: pathlib.Path, files: dict[str, str]) -> None:
    subprocess.run(["git", "-C", str(tmp), "init", "-q"], check=True)
    subprocess.run(["git", "-C", str(tmp), "config", "user.email", "t@t"], check=True)
    subprocess.run(["git", "-C", str(tmp), "config", "user.name", "t"], check=True)
    for rel, content in files.items():
        p = tmp / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    subprocess.run(["git", "-C", str(tmp), "add", "-A"], check=True)
    subprocess.run(["git", "-C", str(tmp), "commit", "-q", "-m", "init"], check=True)


class TestGlobMatch(unittest.TestCase):
    def test_doublestar_crosses_directories(self):
        self.assertTrue(docmaint.glob_match("internal/sched/exec.go", "internal/sched/**"))
        self.assertTrue(docmaint.glob_match("internal/sched/a/b.go", "internal/sched/**"))
        self.assertFalse(docmaint.glob_match("internal/other/exec.go", "internal/sched/**"))

    def test_single_star_stays_within_one_segment(self):
        self.assertTrue(docmaint.glob_match("docs/api.md", "docs/*.md"))
        self.assertFalse(docmaint.glob_match("docs/sub/api.md", "docs/*.md"))


class TestScan(unittest.TestCase):
    def scan(self, files: dict[str, str]):
        with tempfile.TemporaryDirectory() as td:
            tmp = pathlib.Path(td)
            make_repo(tmp, {"docs/DICTIONARY.md": FIXTURE_DICT, **files})
            return docmaint.run_scan(tmp)

    def test_deprecated_term_is_a_violation(self):
        result = self.scan({"docs/guide.md": "Boot the VM before testing.\n"})
        self.assertEqual(len(result.violations), 1)
        v = result.violations[0]
        self.assertEqual((v.path, v.lineno, v.found, v.replacement),
                         ("docs/guide.md", 1, "VM", "box"))

    def test_terms_match_case_insensitively_and_whole_word(self):
        result = self.scan({"docs/guide.md": "the vm boots; vmware is fine\n"})
        self.assertEqual([(v.found, v.lineno) for v in result.violations], [("vm", 1)])

    def test_manual_synonym_is_skipped(self):
        result = self.scan({"docs/guide.md": "In this instance we retry.\n"})
        self.assertEqual(result.violations, [])

    def test_exception_glob_suppresses_hit(self):
        result = self.scan({"internal/sched/exec.go": "type executor struct{}\n"})
        self.assertEqual(result.violations, [])

    def test_same_term_outside_exception_glob_is_flagged(self):
        result = self.scan({"internal/web/exec.go": "executor := New()\n"})
        self.assertEqual([(v.path, v.found) for v in result.violations],
                         [("internal/web/exec.go", "executor")])

    def test_name_case_variant_is_flagged(self):
        result = self.scan({"docs/arch.md": "CredBroker issues tokens.\n"})
        self.assertEqual([(v.found, v.replacement) for v in result.violations],
                         [("CredBroker", "credbroker")])

    def test_name_canonical_case_is_clean(self):
        result = self.scan({"docs/arch.md": "credbroker issues tokens.\n"})
        self.assertEqual(result.violations, [])

    def test_dictionary_itself_is_excluded(self):
        result = self.scan({})  # only the dictionary exists, full of deprecated terms
        self.assertEqual(result.violations, [])

    def test_generated_file_is_excluded(self):
        result = self.scan({"gen/api.md": "// Code generated by protoc. DO NOT EDIT.\nVM\n"})
        self.assertEqual(result.violations, [])

    def test_temporary_exception_with_no_hits_is_removal_candidate(self):
        # No file under internal/sched/** contains "executor".
        result = self.scan({"internal/sched/clean.go": "package sched\n"})
        self.assertEqual(result.candidates, ["executor"])

    def test_temporary_exception_with_hits_is_not_candidate(self):
        result = self.scan({"internal/sched/exec.go": "executor := 1\n"})
        self.assertEqual(result.candidates, [])

    def test_permanent_exception_never_a_candidate(self):
        # pkg/gcp/** matches nothing at all; 'instance' must NOT be reported.
        result = self.scan({"docs/guide.md": "fine text\n"})
        self.assertEqual(result.candidates, ["executor"])  # executor yes, instance no
```

- [ ] **Step 2: Run to verify they fail**

```bash
python3 scripts/docmaint_test.py
```

Expected: FAIL — no attribute `glob_match` / `run_scan`.

- [ ] **Step 3: Implement scan**

Insert into `docmaint` after `parse_dictionary` (and replace the `cmd_scan` stub):

```python
def glob_match(path: str, pattern: str) -> bool:
    """fnmatch-style match where ** crosses directory separators and * does not."""
    out = []
    i = 0
    while i < len(pattern):
        c = pattern[i]
        if c == "*":
            if pattern[i : i + 3] == "**/":
                out.append(r"(?:.*/)?")
                i += 3
                continue
            if pattern[i : i + 2] == "**":
                out.append(r".*")
                i += 2
                continue
            out.append(r"[^/]*")
        elif c == "?":
            out.append(r"[^/]")
        else:
            out.append(re.escape(c))
        i += 1
    return re.fullmatch("".join(out), path) is not None


class Violation:
    def __init__(self, path: str, lineno: int, found: str, replacement: str):
        self.path, self.lineno, self.found, self.replacement = path, lineno, found, replacement


class ScanResult:
    def __init__(self):
        self.violations: list[Violation] = []
        self.candidates: list[str] = []   # temporary-exception terms with zero matches


def _sweepable_files(root: Path) -> list[str]:
    files = []
    for rel in git(root, "ls-files").splitlines():
        if rel == str(DICT_RELPATH) or rel.startswith(SWEEP_EXCLUDE_PREFIXES):
            continue
        files.append(rel)
    return files


def _read_text(root: Path, rel: str) -> str | None:
    try:
        text = (root / rel).read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None
    head = "\n".join(text.splitlines()[:5]).lower()
    if any(marker in head for marker in GENERATED_MARKERS):
        return None
    return text


def _word_re(term: str, ignorecase: bool) -> re.Pattern:
    return re.compile(
        r"(?<![\w-])" + re.escape(term) + r"(?![\w-])",
        re.IGNORECASE if ignorecase else 0,
    )


def run_scan(root: Path) -> ScanResult:
    d = parse_dictionary((root / DICT_RELPATH).read_text(encoding="utf-8"))
    result = ScanResult()

    # (regex, found-label?, replacement, term-key-for-exceptions)
    checks: list[tuple[re.Pattern, str, str]] = []
    for e in d.entries:
        for syn, manual in e.synonyms:
            if manual:
                continue
            checks.append((_word_re(syn, ignorecase=True), e.name, syn))
        if e.section == "Names":
            # Case-variant check: case-insensitive hit whose exact text != canonical.
            checks.append((_word_re(e.name, ignorecase=True), e.name, None))

    exc_hits = {ex.term: 0 for ex in d.exceptions}

    for rel in _sweepable_files(root):
        text = _read_text(root, rel)
        if text is None:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for pattern, canonical, syn in checks:
                for m in pattern.finditer(line):
                    found = m.group(0)
                    if syn is None and found == canonical:
                        continue  # Name in canonical case: clean
                    term_key = syn if syn is not None else found
                    covered = any(
                        ex.term.lower() == term_key.lower()
                        and any(glob_match(rel, g) for g in ex.globs)
                        for ex in d.exceptions
                    )
                    if covered:
                        continue
                    result.violations.append(Violation(rel, lineno, found, canonical))
            # Exception liveness: count term presence inside its own globs.
            for ex in d.exceptions:
                if any(glob_match(rel, g) for g in ex.globs):
                    if _word_re(ex.term, ignorecase=True).search(line):
                        exc_hits[ex.term] += 1

    for ex in d.exceptions:
        if ex.status == "temporary" and exc_hits[ex.term] == 0:
            result.candidates.append(ex.term)
    return result


def cmd_scan(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    result = run_scan(root)
    lines = [
        f"{v.path}:{v.lineno}: '{v.found}' -> use '{v.replacement}'"
        for v in result.violations
    ]
    for term in result.candidates:
        lines.append(
            f"exception '{term}' [temporary] matches nothing under its globs — "
            f"removal candidate (confirm via `git log -S '{term}'` before removing)"
        )
    with tempfile.NamedTemporaryFile(
        "w", delete=False, prefix="docmaint-scan-", suffix=".txt"
    ) as fh:
        fh.write("\n".join(lines) + ("\n" if lines else ""))
        report = fh.name
    print(
        f"scan: {len(result.violations)} violation(s), "
        f"{len(result.candidates)} removal candidate(s)  (report: {report})"
    )
    return 1 if result.violations else 0
```

- [ ] **Step 4: Run the tests, verify all pass**

```bash
python3 scripts/docmaint_test.py
```

Expected: `RESULT run=20 failed=0`.

- [ ] **Step 5: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/scripts/docmaint \
        .claude/skills/auditing-documentation/scripts/docmaint_test.py
git commit -m "skill(maintaining-documentation): docmaint scan — sweep, exceptions, candidates"
```

---

### Task 5: docmaint stamp

**Files:**
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint` (implement stamp helpers + `cmd_stamp`)
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint_test.py` (add tests)

Stamp block format (inherited from OLD, sentinel unchanged for compatibility with already-stamped docs):

```
---
<!-- doc-audit:last-reviewed -->
_Last reviewed: 2026-06-09 · commit `abc1234` · verified against code (2 claims deferred to review)._
```

The parenthetical appears only when deferred > 0. Idempotent: re-stamping replaces the existing block; a trailing `---` rule already at EOF is reused, never duplicated.

- [ ] **Step 1: Add failing tests**

Add to `docmaint_test.py`:

```python
class TestStamp(unittest.TestCase):
    def test_set_appends_block_with_separator(self):
        body = "# Doc\n\nClaims.\n"
        out = docmaint.stamp_text(body, "2026-06-09", "abc1234", deferred=0)
        self.assertTrue(out.endswith(
            "---\n<!-- doc-audit:last-reviewed -->\n"
            "_Last reviewed: 2026-06-09 · commit `abc1234` · verified against code._\n"
        ))
        self.assertTrue(out.startswith("# Doc\n\nClaims.\n"))

    def test_set_reuses_trailing_rule(self):
        body = "# Doc\n\n---\n"
        out = docmaint.stamp_text(body, "2026-06-09", "abc1234", deferred=0)
        self.assertEqual(out.count("---"), 1)

    def test_restamp_is_idempotent(self):
        body = "# Doc\n"
        once = docmaint.stamp_text(body, "2026-06-09", "abc1234", deferred=2)
        twice = docmaint.stamp_text(once, "2026-06-10", "def5678", deferred=0)
        self.assertEqual(twice.count(docmaint.STAMP_SENTINEL), 1)
        self.assertIn("def5678", twice)
        self.assertNotIn("abc1234", twice)
        self.assertNotIn("deferred", twice)

    def test_deferred_recorded_and_parsed(self):
        out = docmaint.stamp_text("# D\n", "2026-06-09", "abc1234", deferred=2)
        self.assertIn("(2 claims deferred to review)", out)
        stamp = docmaint.parse_stamp(out)
        self.assertEqual((stamp.date, stamp.sha, stamp.deferred),
                         ("2026-06-09", "abc1234", 2))

    def test_parse_stamp_absent(self):
        self.assertIsNone(docmaint.parse_stamp("# D\nno stamp here\n"))
```

- [ ] **Step 2: Run to verify they fail**

```bash
python3 scripts/docmaint_test.py
```

Expected: FAIL — no attribute `stamp_text`.

- [ ] **Step 3: Implement stamp**

Insert into `docmaint` (replace the `cmd_stamp` stub):

```python
STAMP_LINE_RE = re.compile(
    r"_Last reviewed: (?P<date>\d{4}-\d{2}-\d{2}) · commit `(?P<sha>[0-9a-f]+)` · "
    r"verified against code(?: \((?P<deferred>\d+) claims? deferred to review\))?\._"
)


class Stamp:
    def __init__(self, date: str, sha: str, deferred: int):
        self.date, self.sha, self.deferred = date, sha, deferred


def parse_stamp(text: str) -> Stamp | None:
    if STAMP_SENTINEL not in text:
        return None
    m = STAMP_LINE_RE.search(text)
    if not m:
        return None
    return Stamp(m.group("date"), m.group("sha"), int(m.group("deferred") or 0))


def _stamp_line(date: str, sha: str, deferred: int) -> str:
    extra = f" ({deferred} claims deferred to review)" if deferred else ""
    return f"_Last reviewed: {date} · commit `{sha}` · verified against code{extra}._"


def stamp_text(text: str, date: str, sha: str, deferred: int) -> str:
    line = _stamp_line(date, sha, deferred)
    if STAMP_SENTINEL in text:
        # Replace the existing block: sentinel line + the stamp line after it.
        text = STAMP_LINE_RE.sub(line, text, count=1)
        return text
    body = text.rstrip("\n")
    if body.endswith("\n---") or body == "---":
        return body + f"\n{STAMP_SENTINEL}\n{line}\n"
    return body + f"\n\n---\n{STAMP_SENTINEL}\n{line}\n"


def cmd_stamp(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    if args.set:
        doc = root / args.set
        sha = git(root, "rev-parse", "--short", "HEAD").strip()
        today = datetime.date.today().isoformat()
        doc.write_text(stamp_text(doc.read_text(encoding="utf-8"), today, sha,
                                  args.deferred), encoding="utf-8")
        print(f"stamped {args.set} @ {sha}"
              + (f" ({args.deferred} deferred)" if args.deferred else ""))
        return 0
    # default / --list: show every stamped markdown file
    for rel in git(root, "ls-files", "*.md").splitlines():
        text = _read_text(root, rel)
        if text is None:
            continue
        stamp = parse_stamp(text)
        if stamp:
            print(f"{rel}\t{stamp.date}\t{stamp.sha}\tdeferred={stamp.deferred}")
    return 0
```

- [ ] **Step 4: Run the tests, verify all pass**

```bash
python3 scripts/docmaint_test.py
```

Expected: `RESULT run=25 failed=0`.

- [ ] **Step 5: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/scripts/docmaint \
        .claude/skills/auditing-documentation/scripts/docmaint_test.py
git commit -m "skill(maintaining-documentation): docmaint stamp — idempotent sentinel read/write"
```

---

### Task 6: docmaint stale

**Files:**
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint` (index parser + `cmd_stale`)
- Modify: `.claude/skills/auditing-documentation/scripts/docmaint_test.py` (add tests)

Index format (normative, from the spec; sentinel-fenced so it's machine-maintainable inside `docs/README.md` or standalone `docs/INDEX.md`):

```markdown
<!-- doc-index:begin -->
| Doc | What | Class | Owns |
| --- | --- | --- | --- |
| `docs/api.md` | HTTP API reference | evergreen | `internal/server/**`, `api/**` |
| `docs/specs/2026-01-15-foo-design.md` | foo design, Jan 2026 | point-in-time | — |
<!-- doc-index:end -->
```

`stale` reports, for every `evergreen` row: `unstamped` (no stamp), `deferred:N` (stamp records deferred claims), or `changed: <paths>` (rename-aware `git diff --name-only -M <sha>..HEAD` intersected with the row's `Owns` globs). Point-in-time rows are skipped. A stamp SHA git can't resolve reports `stamp-sha-unknown`.

- [ ] **Step 1: Add failing tests**

Add to `docmaint_test.py`:

```python
INDEX_BLOCK = """\
# Docs

<!-- doc-index:begin -->
| Doc | What | Class | Owns |
| --- | --- | --- | --- |
| `docs/api.md` | API reference | evergreen | `internal/server/**` |
| `docs/old-design.md` | old design | point-in-time | — |
<!-- doc-index:end -->
"""


class TestStale(unittest.TestCase):
    def make(self, td: str) -> pathlib.Path:
        tmp = pathlib.Path(td)
        make_repo(tmp, {
            "docs/README.md": INDEX_BLOCK,
            "docs/api.md": "# API\n",
            "docs/old-design.md": "# Old\n",
            "internal/server/main.go": "package main\n",
        })
        return tmp

    def stamp_api(self, tmp: pathlib.Path, deferred: int = 0):
        sha = subprocess.run(["git", "-C", str(tmp), "rev-parse", "--short", "HEAD"],
                             capture_output=True, text=True, check=True).stdout.strip()
        p = tmp / "docs/api.md"
        p.write_text(docmaint.stamp_text(p.read_text(), "2026-06-09", sha, deferred))
        subprocess.run(["git", "-C", str(tmp), "commit", "-aqm", "stamp"], check=True)

    def test_unstamped_evergreen_reported_pointintime_skipped(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = self.make(td)
            rows = docmaint.run_stale(tmp)
            self.assertEqual(rows, [("docs/api.md", "unstamped")])

    def test_clean_doc_not_reported(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = self.make(td)
            self.stamp_api(tmp)
            self.assertEqual(docmaint.run_stale(tmp), [])

    def test_owned_change_reported(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = self.make(td)
            self.stamp_api(tmp)
            (tmp / "internal/server/main.go").write_text("package main // changed\n")
            subprocess.run(["git", "-C", str(tmp), "commit", "-aqm", "change"], check=True)
            rows = docmaint.run_stale(tmp)
            self.assertEqual(rows, [("docs/api.md", "changed: internal/server/main.go")])

    def test_unowned_change_not_reported(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = self.make(td)
            self.stamp_api(tmp)
            (tmp / "README.md").write_text("top\n")
            subprocess.run(["git", "-C", str(tmp), "add", "-A"], check=True)
            subprocess.run(["git", "-C", str(tmp), "commit", "-qm", "unrelated"], check=True)
            self.assertEqual(docmaint.run_stale(tmp), [])

    def test_deferred_claims_always_on_worklist(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = self.make(td)
            self.stamp_api(tmp, deferred=2)
            self.assertEqual(docmaint.run_stale(tmp), [("docs/api.md", "deferred:2")])
```

- [ ] **Step 2: Run to verify they fail**

```bash
python3 scripts/docmaint_test.py
```

Expected: FAIL — no attribute `run_stale`.

- [ ] **Step 3: Implement stale**

Insert into `docmaint` (replace the `cmd_stale` stub):

```python
class IndexRow:
    def __init__(self, doc: str, klass: str, owns: list[str]):
        self.doc, self.klass, self.owns = doc, klass, owns


def find_index(root: Path) -> Path | None:
    for rel in ("docs/README.md", "docs/INDEX.md"):
        p = root / rel
        if p.exists() and INDEX_BEGIN in p.read_text(encoding="utf-8"):
            return p
    return None


def parse_index(text: str) -> list[IndexRow]:
    rows = []
    inside = False
    for line in text.splitlines():
        if line.strip() == INDEX_BEGIN:
            inside = True
            continue
        if line.strip() == INDEX_END:
            break
        if not inside or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 4 or cells[0] in ("Doc", "---", "—") or set(cells[0]) == {"-"}:
            continue
        doc = cells[0].strip("`")
        klass = cells[2]
        owns = [] if cells[3] in ("—", "-", "") else [g.strip("` ") for g in cells[3].split(",")]
        rows.append(IndexRow(doc, klass, owns))
    return rows


def run_stale(root: Path) -> list[tuple[str, str]]:
    index_path = find_index(root)
    if index_path is None:
        raise SystemExit("stale: no doc index found (docs/README.md or docs/INDEX.md "
                         f"with {INDEX_BEGIN})")
    out = []
    diff_cache: dict[str, list[str]] = {}
    for row in parse_index(index_path.read_text(encoding="utf-8")):
        if row.klass != "evergreen":
            continue
        try:
            text = (root / row.doc).read_text(encoding="utf-8")
        except OSError:
            out.append((row.doc, "missing"))
            continue
        stamp = parse_stamp(text)
        if stamp is None:
            out.append((row.doc, "unstamped"))
            continue
        if stamp.deferred:
            out.append((row.doc, f"deferred:{stamp.deferred}"))
            continue
        if stamp.sha not in diff_cache:
            try:
                diff_cache[stamp.sha] = git(
                    root, "diff", "--name-only", "-M", f"{stamp.sha}..HEAD"
                ).splitlines()
            except subprocess.CalledProcessError:
                out.append((row.doc, "stamp-sha-unknown"))
                continue
        changed = [p for p in diff_cache[stamp.sha]
                   if any(glob_match(p, g) for g in row.owns)]
        if changed:
            shown = ",".join(changed[:3]) + (f" (+{len(changed)-3} more)" if len(changed) > 3 else "")
            out.append((row.doc, f"changed: {shown}"))
    return out


def cmd_stale(args: argparse.Namespace) -> int:
    for doc, reason in run_stale(args.root.resolve()):
        print(f"{doc}\t{reason}")
    return 0
```

- [ ] **Step 4: Run the tests, verify all pass**

```bash
python3 scripts/docmaint_test.py
```

Expected: `RESULT run=30 failed=0`.

- [ ] **Step 5: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/scripts/docmaint \
        .claude/skills/auditing-documentation/scripts/docmaint_test.py
git commit -m "skill(maintaining-documentation): docmaint stale — index-driven staleness triage"
```

---

### Task 7: Wire docmaint tests into the dotfiles test harness

**Files:**
- Create: `test/test_docmaint.sh`

`test/run.sh` runs every `test/test_*.sh` and expects a final `RESULT run=<n> failed=<n>` line — which `docmaint_test.py` already prints.

- [ ] **Step 1: Write the wrapper**

Create `test/test_docmaint.sh`:

```sh
#!/bin/sh
# test_docmaint.sh — run the maintaining-documentation skill's Python tests.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
SKILL="$HERE/../.claude/skills/maintaining-documentation"
[ -d "$SKILL" ] || SKILL="$HERE/../.claude/skills/auditing-documentation"
python3 "$SKILL/scripts/docmaint_test.py" 2>&1
```

(The fallback line keeps the wrapper working both before and after the Task 15 rename.)

- [ ] **Step 2: Run the whole harness, verify it passes**

```bash
cd /Users/jesse/git/dotfiles
sh test/run.sh
```

Expected: existing tests still pass; new section `== test_docmaint.sh ==` shows `RESULT run=30 failed=0`; final line `TOTAL run=<n> failed=0`, exit 0.

- [ ] **Step 3: Commit**

```bash
git add test/test_docmaint.sh
git commit -m "test: wire docmaint unit tests into test/run.sh harness"
```

---

### Task 8: templates — DICTIONARY-template.md and INDEX-template.md

**Files:**
- Create: `.claude/skills/auditing-documentation/templates/DICTIONARY-template.md`
- Create: `.claude/skills/auditing-documentation/templates/INDEX-template.md`

- [ ] **Step 1: Write DICTIONARY-template.md** (exact content):

````markdown
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
````

(No stamp block in the template — bootstrap stamps the instantiated dictionary
with `docmaint stamp --set docs/DICTIONARY.md`, which appends a fresh block.)

- [ ] **Step 2: Write INDEX-template.md** (exact content):

````markdown
# Documentation Index

One row per doc. `Class` is the confirmed evergreen/point-in-time
classification of record (the classify-and-confirm gate's output). `Owns` is
machine-readable: the path globs whose facts this doc owns — `docmaint stale`
diffs them; `—` for point-in-time docs. The fenced table is machine-maintained;
edit rows, never the sentinels.

<!-- doc-index:begin -->
| Doc | What | Class | Owns |
| --- | --- | --- | --- |
| `docs/DICTIONARY.md` | project dictionary (normative terminology) | evergreen | `docs/**` |
<!-- doc-index:end -->
````

- [ ] **Step 3: Sanity-check the templates against docmaint**

```bash
cd /Users/jesse/git/dotfiles/.claude/skills/auditing-documentation
python3 - <<'EOF'
import importlib.machinery, importlib.util, pathlib
loader = importlib.machinery.SourceFileLoader("docmaint", "scripts/docmaint")
spec = importlib.util.spec_from_loader("docmaint", loader)
m = importlib.util.module_from_spec(spec); loader.exec_module(m)
d = m.parse_dictionary(pathlib.Path("templates/DICTIONARY-template.md").read_text())
assert d.entries == [] and d.exceptions == [], "template must parse to empty dictionary"
rows = m.parse_index(pathlib.Path("templates/INDEX-template.md").read_text())
assert len(rows) == 1 and rows[0].doc == "docs/DICTIONARY.md", rows
print("templates parse OK")
EOF
```

Expected: `templates parse OK`.

- [ ] **Step 4: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/templates/
git commit -m "skill(maintaining-documentation): dictionary and index templates"
```

---

### Task 9: references/audit.md (move the audit process out of OLD)

**Files:**
- Create: `.claude/skills/auditing-documentation/references/audit.md`
- (OLD SKILL.md is not modified here — it's replaced wholesale in Task 14.)

`references/audit.md` = OLD's **Process** section (lines under `## Process`, Phases 0–4) plus the per-doc mechanics, with these exact edits. Everything law-like (classification gate, rubric, scope, verify-the-verb, red flags, rationalizations, stamp contract) stays OUT — it lands in the hub (Task 14), and audit.md points there.

- [ ] **Step 1: Create the file with this exact structure and content**

Start from OLD's `## Process` section text (copy it verbatim), then apply these edits:

1. Add this header above everything:

````markdown
# Full audit (Phases 0–4)

**Law lives in the hub (SKILL.md):** the classify-and-confirm gate, the
auto-fix rubric (incl. the dictionary clause), scope & exclusions,
verify-the-claim-not-the-symbol, the stamping precondition, red flags, and
rationalizations all bind here and are NOT restated. Read SKILL.md first.
````

2. In **Phase 0**, replace the sentence `Propose the group-level classification; **confirm with the human**.` with:

````markdown
Propose the group-level classification; **confirm with the human**, then
persist it: create or update the doc index (`docs/README.md` fenced table, or
`docs/INDEX.md` — see the hub's artifact conventions) with each doc's `Class`
and `Owns` globs. The index is the classification of record; later flows gate
on it instead of re-interviewing.
````

3. In **Phase 4**, replace `independent/competing agents, fed the canonical-owner scheme:` with `independent/competing agents, fed the doc index (its Owns column is the canonical-owner scheme):`

4. In **Phase 4**, append a fifth bullet:

````markdown
- **Terminology** — run `scripts/docmaint scan` against the repo. Apply the
  rubric's dictionary clause to violations in evergreen prose; everything else
  (code identifiers, UI strings) is a finding → interview (rename / add entry /
  add exception). Zero-match `[temporary]` exceptions are removal candidates —
  confirm via git history (`git log -S`) before removing; `[permanent]`
  exceptions are never touched. New recurring terms with no entry → dictionary
  interview. Finish by updating the index: new docs get rows, dead rows go.
````

5. In **Phase 3**, after `Only then **stamp the last-reviewed marker** on the verified evergreen docs,` add: `(use `docmaint stamp --set <doc> [--deferred N]` — it is idempotent and records deferred-claim counts),`

6. Append at the end (replacing OLD's standalone `## Last-reviewed marker` section, whose contract moves to the hub):

````markdown
## Stamping mechanics

Stamp with `scripts/docmaint stamp --set <doc> [--deferred N]` — idempotent,
reuses a trailing `---`, never stacks duplicates. Record deferred counts
honestly: a deferred claim keeps the doc on the incremental worklist (see the
hub's stamp contract). Stamp only docs you verified; never stamp point-in-time
docs.
````

- [ ] **Step 2: Verify no law was duplicated**

```bash
cd /Users/jesse/git/dotfiles/.claude/skills/auditing-documentation
grep -c "Auto-fix a claim" references/audit.md   # expect 0 (rubric lives in hub)
grep -c "Phase" references/audit.md              # expect >0 (process moved here)
```

- [ ] **Step 3: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/references/audit.md
git commit -m "skill(maintaining-documentation): move audit process to references/audit.md"
```

---

### Task 10: references/dictionary.md

**Files:**
- Create: `.claude/skills/auditing-documentation/references/dictionary.md`

- [ ] **Step 1: Create with this exact content**

````markdown
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
     conflated (the *box*/*runner* class). These are the highest-value entries.
   - **Recurring project terms:** project-specific or non-standard usage that
     repeats across docs/code. Skip industry-standard vocabulary.
3. Interview, bounded: present the candidate list with proposed 1–2 sentence
   definitions in one batch. The human approves/edits/cuts. Load-bearing and
   ambiguous terms only — a dictionary you can read in one sitting.
4. Instantiate `templates/DICTIONARY-template.md` at `docs/DICTIONARY.md`
   (create `docs/` if absent), fill approved entries, add an index row
   (Class: evergreen), and stamp it (`docmaint stamp --set docs/DICTIONARY.md`).
5. Run `scripts/docmaint scan`. Triage per the hub's governance rules; expect a
   first wave of findings — that's the point. Leave fixes uncommitted for
   review.

## Adding / revising an entry

- New term spotted (in review, audit, or conversation): draft the entry
  (definition, Distinct from:, Use instead of:), confirm with the human, add
  in alphabetical order within its section.
- Deprecating a term: move it onto the winner's `Use instead of:` line. If
  live code still uses it, add a `[temporary]` exception with a tracking
  pointer in the same edit — never leave scan red on known divergences.
- A synonym that is ordinary English in prose gets `[manual]` — scan skips it;
  audits check it by hand.

## Exception lifecycle

- **Add:** term + path globs (never prose predicates) + reason +
  `[temporary]` (with tracking pointer) or `[permanent]`.
- **Remove a `[temporary]`:** only after `docmaint scan` reports it as a
  removal candidate AND git history confirms resolution
  (`git log -S '<term>' -- <glob-dir>` shows the rename landed, not that the
  code moved elsewhere). A grep miss alone is not proof — rubric clause 5.
- **`[permanent]`:** never removed by scan evidence. Revisit only when the
  human says the upstream reality changed.

## After any dictionary edit

Re-run `scripts/docmaint scan` (the dictionary governs the whole corpus, so an
edit can create or clear violations anywhere), restamp the dictionary, and
leave everything uncommitted for human review.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/references/dictionary.md
git commit -m "skill(maintaining-documentation): dictionary flow reference"
```

---

### Task 11: references/incremental.md

**Files:**
- Create: `.claude/skills/auditing-documentation/references/incremental.md`

- [ ] **Step 1: Create with this exact content**

````markdown
# Incremental re-audit (routine, cheap)

Law lives in the hub: rubric, gate, stamping precondition, stamp contract.
**Triage, not soundness** — `stale` narrows the worklist; it never proves a
doc clean. Full audits (references/audit.md) remain the ground-truth pass.

## Preconditions

A doc index with confirmed `Class` values, and stamps from a prior audit.
Missing either → run references/audit.md instead. Never classify by gut here.

## Process

1. Worklist: `scripts/docmaint stale`. Reasons mean:
   - `changed: <paths>` — owned ground truth moved; re-verify the doc's claims
     against those paths (verify the verb, not the noun — hub law).
   - `deferred:N` — the last audit left N claims uninterviewed; they stay on
     the list until resolved, regardless of code changes.
   - `unstamped` / `missing` / `stamp-sha-unknown` — not incremental material;
     route to a full audit of that doc.
2. Also run `scripts/docmaint scan` — terminology never depends on stamps, and
   a dictionary change since the last run surfaces here.
3. For each worklist doc: re-verify only the affected claims under the hub
   rubric. Auto-fix what's determinate; interview the rest (bounded — defer
   the tail with `--deferred N` honestly recorded).
4. Stamping precondition (hub law): at least one independent verifier subagent
   re-checks the applied edits with citations. Then
   `docmaint stamp --set <doc> [--deferred N]`.
5. Leave everything uncommitted for human review.

## External ground truth

Claims whose truth lives outside this repo (another repo, a vendor binary, a
hosted service) never appear in `stale` output. They are cleared only by full
audits — when reading a doc here, treat such claims as unverified, not stale.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/references/incremental.md
git commit -m "skill(maintaining-documentation): incremental re-audit flow reference"
```

---

### Task 12: references/write-path.md

**Files:**
- Create: `.claude/skills/auditing-documentation/references/write-path.md`

- [ ] **Step 1: Create with this exact content**

````markdown
# Write-path: docs ride along with code changes

Law lives in the hub. This flow is **bounded by the diff by construction** —
if it stops being cheap, it stops happening. Run it when finishing code work,
before requesting review.

## Preconditions

A doc index with confirmed `Class` values. None → offer to run
references/audit.md Phase 0 first (one-time cost); do NOT edit docs against an
unconfirmed classification.

## Process

1. Get the change surface: `git diff --name-only -M <base>...HEAD` (plus
   uncommitted changes if relevant).
2. Map changed paths against the index's `Owns` globs → the owning evergreen
   docs. No owner for a surface that plainly needs documenting → note it as a
   finding; do not invent a doc (pragmatism law: name the reader first).
3. For each owning doc, re-verify only the claims the diff touches, under the
   hub rubric: auto-fix determinate drift; collect the rest for the human as
   part of the change's review notes. Never edit point-in-time docs.
4. New terms: if the change introduces a recurring term or renames a concept,
   route to references/dictionary.md (entry or exception — e.g. a rename in
   flight gets a `[temporary]` exception in the same change).
5. Run `scripts/docmaint scan`; fix violations your change introduced.
6. Stamping precondition (hub law): at least one independent verifier subagent
   re-checks the applied doc edits with citations. Then
   `docmaint stamp --set <doc>` for each verified doc.
7. The doc edits join the change's commits. Commit messages use dictionary
   terms — this is the only place commit-message conformance is enforced.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/references/write-path.md
git commit -m "skill(maintaining-documentation): write-path flow reference"
```

---

### Task 13: references/new-docs.md

**Files:**
- Create: `.claude/skills/auditing-documentation/references/new-docs.md`

- [ ] **Step 1: Create with this exact content**

````markdown
# New docs: born conformant

Law lives in the hub. First exit wins:

1. **Don't write it.** Name the reader. If no specific human or agent needs
   this doc, stop — file a note instead. A coverage gap is a finding, not a
   mandate (pragmatism law).
2. **Classify before creating** — the doc's contract, not its folder:
   - Records a decision/design/plan as of now → **point-in-time**: dated
     filename (`YYYY-MM-DD-<topic>.md`), under the project's specs/plans dir,
     never stamped, index row with Class `point-in-time`, Owns `—`.
   - Describes current reality and must track it → **evergreen**: undated
     name, lives with the evergreen docs, and continues below.
3. **Evergreen birth checklist:**
   - Terms conform to `docs/DICTIONARY.md`; new recurring terms go through
     references/dictionary.md in the same change.
   - Mechanical claims (paths, flags, routes, config) carry verifiable
     citations — written against the code path that enacts them (verify the
     verb — hub law).
   - Add the index row: one-liner for readers, Class `evergreen`, `Owns` globs
     for the surfaces whose facts it owns (machine-readable — `docmaint stale`
     will diff them).
   - Run `scripts/docmaint scan`; fix what the new doc introduced.
   - Verify, then stamp: `docmaint stamp --set <doc>` (stamping precondition
     applies — an independent verifier re-checks before the stamp).
4. **Don't duplicate.** If the fact already has a canonical owner, link to it;
   the new doc owns only what nothing else owns (one fact, one owner).
````

- [ ] **Step 2: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/references/new-docs.md
git commit -m "skill(maintaining-documentation): new-docs flow reference"
```

---

### Task 14: Rewrite SKILL.md as the hub

**Files:**
- Modify: `.claude/skills/auditing-documentation/SKILL.md` (full replacement)

Compose the new SKILL.md from OLD + new law. Structure and exact new content below; sections marked **[FROM OLD]** are copied verbatim from OLD SKILL.md except where an edit is specified. Keep OLD's voice (terse, imperative).

- [ ] **Step 1: Replace SKILL.md with the following composition**

Frontmatter (exact):

````markdown
---
name: maintaining-documentation
description: Use when documentation needs creating, checking, or maintaining — docs may have drifted from code, pre-release doc verification, updating docs after finishing code work, adding or enforcing project terminology, deciding where a new doc should live, or a routine re-audit of previously verified docs.
---
````

Then these sections, in order:

**1. `# Maintaining Documentation` + Overview** — rewrite OLD's Overview to cover maintenance (new text, exact):

````markdown
## Overview

A doc is a set of **claims about reality**; this skill keeps a project's docs
matching reality over time. The same law binds every flow: decide whether a doc
is even supposed to track current reality (classify first), auto-fix only what
is *determinate*, route everything ambiguous to the human, and never rewrite a
historical record. **Violating the letter of these rules is violating the
spirit of them.**

## Dispatch — read the flow file before doing anything

| Situation | You MUST read |
| --- | --- |
| Full audit: "docs are out of date", pre-release, untrusted doc set | `references/audit.md` |
| Routine re-check of previously audited docs | `references/incremental.md` |
| Just finished code work; update the docs that ride along | `references/write-path.md` |
| Create/extend the dictionary; term disputes; exceptions | `references/dictionary.md` |
| Writing a brand-new doc; "where does this doc go?" | `references/new-docs.md` |

These are hard gates: do not start a flow from memory of this table. Flows add
process; the law below binds all of them and is never restated in flow files.
````

**2. `## STOP: classify before you edit`** — **[FROM OLD]** verbatim, then append (exact):

````markdown
The confirmed classification **persists in the doc index** (`Class` column —
see Artifacts). Editing flows gate on it: no index → run audit Phase 0 first.
Never classify by gut mid-flow.
````

**3. `## Scope & exclusions`** — **[FROM OLD]** verbatim, plus one sentence appended: `The dictionary (docs/DICTIONARY.md) is excluded from its own terminology sweep.`

**4. `## The rubric: what may be auto-fixed`** — **[FROM OLD]** verbatim (all 5 conditions + the always-interview list), plus this appended subsection (exact):

````markdown
**Dictionary clause.** In evergreen prose only, a deprecated synonym may be
auto-fixed when ALL hold: the synonym maps to exactly one dictionary entry
(whose heading is the replacement); the match is whole-word; no exception
covers it; and the replacement leaves the surrounding sentence true. The
determinant is the dictionary instead of a code counterpart — conditions 1, 4
and 5 still apply. Code identifiers, UI strings: never auto-fixed — findings
only (rename / add entry / add exception). Commit messages: dictionary terms
in new ones; history is never flagged.
````

**5. `## Verify the claim, not just the symbol`** — **[FROM OLD]** verbatim.

**6. `## Artifacts: dictionary and index`** (new, exact):

````markdown
## Artifacts: dictionary and index

The skill maintains exactly **two** artifacts per project, plus inline stamps.
Never a third metadata file.

- **`docs/DICTIONARY.md`** — normative terminology for docs, code identifiers,
  commit messages, and UI strings; divergences live in its Exceptions section,
  scoped by path globs only. Template: `templates/DICTIONARY-template.md`;
  grammar and lifecycle: `references/dictionary.md`. Evergreen, stamped, and
  the canonical owner of terminology.
- **The doc index** — a sentinel-fenced table (`<!-- doc-index:begin/end -->`)
  in `docs/README.md`, or standalone `docs/INDEX.md` where no README exists.
  Columns: Doc | What | Class | Owns. `Class` is the persisted
  classify-and-confirm output; `Owns` is machine-readable path globs (what
  `docmaint stale` diffs). Template: `templates/INDEX-template.md`.
- **`scripts/docmaint`** (`scan | stamp | stale`, `--help` for usage) does the
  mechanical work. It never edits docs; agents do, under the rubric.
````

**7. `## Stamp contract`** (new — REPLACES OLD's "Last-reviewed marker" section; exact):

````markdown
## Stamp contract

Evergreen docs carry one idempotent block at EOF (`docmaint stamp` maintains
it; sentinel `<!-- doc-audit:last-reviewed -->`):

```
---
<!-- doc-audit:last-reviewed -->
_Last reviewed: 2026-06-09 · commit `abc1234` · verified against code (2 claims deferred to review)._
```

The SHA is provenance **and** the incremental cursor — a deliberate change
from the predecessor skill. Incremental re-audits are **triage, not
soundness**: deferred claims keep a doc on the worklist regardless of SHA;
claims with ground truth outside the repo are cleared only by full audits;
terminology never depends on stamps (`docmaint scan` full-sweeps every run).
**Stamping precondition (all flows):** no stamp without independent
verification of the applied edits — full audits use two or more competing
verifiers (Phase 3); diff- or worklist-bounded flows use at least one
independent verifier. Don't stamp point-in-time docs. Stamp only what you
verified.
````

**8. `## Pragmatism law`** (new, exact):

````markdown
## Pragmatism law

- Docs exist for readers. Before creating any doc, entry, or artifact, name
  the reader. No reader → don't write it.
- Adopt existing structures before imposing new ones.
- Two artifacts per project (dictionary, index) plus stamps. Never a third.
- A coverage gap is a finding to file, not a mandate to generate a doc.
- The dictionary stays readable in one sitting: load-bearing terms only.
- Write-path stays bounded by the diff. If maintenance isn't cheap, it won't
  happen.
````

**9. `## Red flags — STOP`** — **[FROM OLD]** verbatim, plus these appended bullets (exact):

````markdown
- About to remove a `[permanent]` exception, or a `[temporary]` one on scan
  evidence alone. → Permanent: never. Temporary: confirm via git history
  first (a grep miss is not resolution).
- About to stamp a doc whose edits nobody independently verified. → The
  stamping precondition applies in every flow, not just full audits.
- About to write a doc, or a dictionary entry, no one asked to read. → Name
  the reader (pragmatism law).
- About to add a third per-project metadata file. → Two artifacts. Never a
  third.
- About to write an exception scope in prose ("code touching X"). → Path
  globs only.
- Editing docs in a project with no confirmed index `Class` column. → Run
  audit Phase 0 first.
````

**10. `## Rationalizations`** — **[FROM OLD]** verbatim table, plus these appended rows (exact):

````markdown
| "Scan found zero hits, the exception is resolved." | A grep miss is not resolution — confirm via `git log -S` first; `[permanent]` exceptions are never removed on scan evidence. |
| "It's a tiny doc edit, stamping without a verifier is fine." | The stamp *means* independently verified. No verifier, no stamp. |
| "The docs feel incomplete, I'll add a doc for each gap." | Gaps are findings. A doc with no reader is debt, not coverage. |
````

**11. `## Common mistakes`** — **[FROM OLD]** verbatim (all bullets — they read as law and stay in the hub), plus one appended bullet: `- Treating stale output as proof of cleanliness — it is triage; soundness comes from full audits.`

- [ ] **Step 2: Verify the hub**

```bash
cd /Users/jesse/git/dotfiles/.claude/skills/auditing-documentation
head -4 SKILL.md                      # frontmatter: name maintaining-documentation + description
grep -c "references/" SKILL.md        # expect >= 5 (dispatch table wired)
grep -c "fan out one subagent" SKILL.md   # expect 0 (process moved to audit.md)
grep -c "^## Process" SKILL.md        # expect 0 (process moved to audit.md)
wc -c SKILL.md                        # expect smaller than OLD's 14417 bytes
```

- [ ] **Step 3: Commit**

```bash
cd /Users/jesse/git/dotfiles
git add .claude/skills/auditing-documentation/SKILL.md
git commit -m "skill(maintaining-documentation): rewrite SKILL.md as hub — law + dispatch"
```

---

### Task 15: Rename, manifest, redeploy

**Files:**
- Rename: `.claude/skills/auditing-documentation/` → `.claude/skills/maintaining-documentation/`
- Modify: `manifest` (the line `.claude/skills/auditing-documentation`)

- [ ] **Step 1: git mv and manifest edit**

```bash
cd /Users/jesse/git/dotfiles
git mv .claude/skills/auditing-documentation .claude/skills/maintaining-documentation
```

In `manifest`, change the line `.claude/skills/auditing-documentation` to `.claude/skills/maintaining-documentation`, keeping the list alphabetical: the line moves to sit between `.claude/skills/e2e-scenario-testing` and `.claude/skills/mcp-cli`.

- [ ] **Step 2: Run tests (wrapper must still find the renamed dir)**

```bash
sh test/run.sh
```

Expected: `TOTAL run=<n> failed=0`.

- [ ] **Step 3: Commit**

```bash
git add manifest
git commit -m "skill: rename auditing-documentation -> maintaining-documentation"
# git mv stages the rename already; verify nothing unrelated is staged first:
git status --short
```

- [ ] **Step 4: Redeploy via homedir-manager**

Use the **managing-homedir skill** (it owns the deploy workflow and symlink lifecycle) to apply the manifest change. Then verify:

```bash
ls -la ~/.claude/skills/ | grep -E "auditing|maintaining"
```

Expected: `maintaining-documentation -> /Users/jesse/git/dotfiles/.claude/skills/maintaining-documentation`; NO `auditing-documentation` entry remains. If the old symlink lingers, remove it per the managing-homedir skill's audit step (it is homedir-manager-managed; don't hand-delete without checking that skill's guidance).

---

### Task 16: Smoke validation (light, per spec)

**Files:** none (read-only checks + a /tmp artifact)

- [ ] **Step 1: Dispatch smoke test**

For each of the five situations below, dispatch a subagent with ONLY the new SKILL.md content and the question "Which file must you read before proceeding, and what may you NOT do before reading it?" Expect the right reference file each time:

1. "The README looks out of date relative to the code." → `references/audit.md`
2. "Quick routine doc check, we audited last month." → `references/incremental.md`
3. "I just merged a feature branch; bring the docs along." → `references/write-path.md`
4. "We keep arguing whether it's a 'box' or a 'VM'." → `references/dictionary.md`
5. "I want to add an architecture overview doc." → `references/new-docs.md`

Any miss → fix the dispatch table wording, re-test that case.

- [ ] **Step 2: Bootstrap dry-run on a real repo**

Following `references/dictionary.md`, run the bootstrap mining steps against `/Users/jesse/git/superpowers-workspace/superpowers-cloud-server` (rich vocabulary: box, runner, credbroker, bastion, nonce). Produce the candidate list + draft entries to `/tmp/dictionary-bootstrap-dryrun.md`. Do NOT write into that repo. Present the draft to Jesse as the judge of output quality.

- [ ] **Step 3: Report**

Summarize: dispatch results (5/5?), dry-run quality, and any skill-text fixes made. The full pressure-scenario battery is deferred by explicit decision — say so in the report.

---

## Self-review (run after drafting, before handoff)

- **Spec coverage:** hub contents (✓ T14), five references (✓ T9–T13), two templates (✓ T8), docmaint scan/stamp/stale (✓ T2–T6), test-harness integration (✓ T7), rename+manifest+redeploy (✓ T15), light validation (✓ T16), description drafted (✓ T14), stamping precondition (✓ T14.7, T11.4, T12.6), exceptions protocol (✓ T4 tests, T10), index schema with Class/Owns (✓ T6, T8).
- **Placeholder scan:** none — every file's content or exact edit is in its task.
- **Consistency:** sentinel strings (`doc-audit:last-reviewed`, `doc-index:begin/end`) identical across T5/T6/T8/T14; `docmaint` flag spellings (`--set`, `--deferred`, `--list`, `--root`) identical across T2/T5/T9/T11/T12/T13; dictionary grammar identical in T3 fixture, T8 template, and T14 rubric clause.
