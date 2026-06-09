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
