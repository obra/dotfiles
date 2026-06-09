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

    def test_exactly_one_terminal_period_stripped(self):
        # Only ONE sentence-ending period comes off; an abbreviation period
        # immediately before it survives. (Grammar: optional trailing period.)
        d = docmaint.parse_dictionary("## Terms\n### usa\nUse instead of: eagle, U.S..\n")
        self.assertEqual(d.entries[0].synonyms, [("eagle", False), ("U.S.", False)])


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


if __name__ == "__main__":
    result = unittest.main(exit=False).result
    failed = len(result.failures) + len(result.errors)
    print(f"RESULT run={result.testsRun} failed={failed}")
    sys.exit(1 if failed else 0)
