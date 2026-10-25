---
name: auditing-codebase-debt
description: Use when asked for a deep, comprehensive, or repo-wide audit of technical debt, LLM slop, duplication, dead code, or legacy/compat accretion, especially on a codebase too large for one context, or when planning how to clean such debt up in waves of PRs.
---

# Auditing Codebase Debt

## Overview

A repo-wide debt audit is a fan-out: many scoped finders, each checked by an adversarial verifier, then a synthesis that groups findings by root cause and an ordered roadmap. The output is a design record of files on disk, committed as a PR. A summary in chat is not the deliverable.

**Core principle:** every finding is checked by an adversarial verifier before anything downstream trusts it. When this was used on a real repo, verifiers downgraded or re-planned about half of the findings.

## Process

1. **Isolate.** Create a worktree off the default branch. Agents write only report files, never source.
2. **Size the repo before slicing.** Count lines by language and by directory, and count tests separately from production code. Target 5–20k lines per slice. Split oversized packages by file prefix (`session_*`, `delegate_*`). Split large flat directories alphabetically into halves.
3. **Build the slice list** (taxonomy below). Every directory with meaningful code needs exactly one owner.
4. **Run the workflow** from `workflow-template.js`. Each slice goes through a finder and then a verifier as a pipeline with no barrier. After a barrier come synthesis, then roadmap, then the completeness critic. Write outputs to `<worktree>/docs/.../audits/<date>-<topic>/{raw/*.md, verified/*.json, SYNTHESIS.md, ROADMAP.md, GAPS.md}`. Later stages read these files instead of having findings pasted into their prompts.
5. **Spot-check the headline claims yourself** before reporting. Synthesis agents overstate: a gate that was partly disarmed got reported as "disarmed", and a refactor got labelled a "defect". Open the code for each defect you plan to tell the user about.
6. **Fold the critic's gaps back into the roadmap.** Then commit the folder and open a docs PR.

## Slice taxonomy

| Kind | Examples |
|---|---|
| Per-area production | one slice per package or package-chunk; for each god package, ask whether it should be split |
| Test code | each big test tree as its own slice: helper and fixture sprawl, tests of mocks, assertions on copy, coverage-chasing files |
| Build/gates | Makefile, CI, scripts, meta/audit tests, budgets |
| Cross-cutting | cross-client duplication (shared lib vs apps); cross-language protocol mirrors; duplicate helper functions (catalog by purpose, then cluster); dead code (cheap static tools allowed); compat/legacy/TODO inventory; docs drift and broken links; error-handling/slop patterns (swallowed errors, single-impl interfaces, pass-through wrappers, narration comments, giant functions, mutable func-var seams) |
| Default sweeps (missed without an owner) | test-seam libraries in production signatures (e.g. in-memory FS); committed fuzz corpora, generated bundles, binaries over 1 MB; logging consistency; goroutine/context lifetime (`context.Background()` in request paths); toolchain/dependency version skew across package trees; test suites in a third language that no gate runs |

## Finding schema (structured output)

`id` (`slice-N`), `title`, `category` (duplication | dead-code | slop | complexity | test-debt | doc-drift | compat-legacy | inconsistency | architecture), `severity` (high = causes bugs/drift; medium = worth a PR; low = cosmetic), `locations` (file:line actually opened), `evidence` (quotes, counts), `impact`, `fix_plan` (canonical home, what is deleted, test strategy, docs), `fix_size_loc`, `risk`, `cross_cutting`.

The verifier returns, for each id, `verdict` (confirmed | partial | refuted), a possibly revised `severity`, a `note`, and `revised_fix_plan`. It defaults to refuted when it cannot confirm.

## Ground rules to put in every agent prompt

- Read-only for source. Write only the named report file. No checkout, stash or commit.
- Run no test suites or race loops; a shared box can't take dozens of concurrent runs. grep, wc, git log/blame, and single-package vet are fine.
- Cite file:line you opened. Leave out speculation.
- Fix plans follow the repo's own rules (read its AGENTS.md/CLAUDE.md and product docs): delete before adding, consolidate into one canonical home, no new compat without approval, behavior tests before behavior changes. Size estimates are in lines, never time.
- Verifiers check that "duplicates" really are semantically identical, and that "dead" code has no callers anywhere (other languages, build tags, scripts, registration by name).

## Roadmap shape

- **Wave 0:** guardrails, small defects (red test first), deletions of verified-dead code.
- **Wave 1:** consolidations.
- **Wave 2:** structural splits, each marked "needs design discussion".
- Give each PR item: findings, files, steps, test strategy, docs, net LOC, risk, gate, dependencies.
- Put PRs that touch the same files in the same **lane** and merge them in order. PRs in different lanes run in parallel worktrees.
- Collect policy calls as named questions for the human (for example, "Version-skew policy", "Coverage floor as a gate"), with the items each one unblocks.
- Guardrails reuse existing lint and review tooling. Be skeptical of new meta-tests.

## Common mistakes

| Mistake | Fix |
|---|---|
| Skipping verification to save tokens | Verifiers are where accuracy comes from. Keep one per slice. |
| Pasting all findings into the synthesis prompt | Give it a compact index of id/title/severity/verdict. It reads the details from files. |
| Relaying synthesis "defects" verbatim | Re-open the code for every claim you put in front of the user. |
| Slicing by guess | Measure first. A single package can be 100k lines. |
| Trusting counts in the plan | Re-derive counts at PR start. |
| Deleting test-only production code without migrating tests | Move the tests to the production path first, then delete. |
