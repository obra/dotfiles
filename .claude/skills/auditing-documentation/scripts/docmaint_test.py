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


if __name__ == "__main__":
    result = unittest.main(exit=False).result
    failed = len(result.failures) + len(result.errors)
    print(f"RESULT run={result.testsRun} failed={failed}")
    sys.exit(1 if failed else 0)
