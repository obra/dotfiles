---
name: implementing-features
description: Use when Jesse requests a software feature or behavior change, including unfinished delivery or ambiguous shared-client scope.
---

# Implementing Features

Deliver agreed behavior through verified merge and cleanup. Resume using current evidence.

## Ordered workflow and quick reference

Load exact skill identifiers at their stages. Missing required capabilities block that stage.

| Stage | Required outcome |
|---|---|
| 1. Human intent | Read repository instructions and product contracts. Agree acceptance criteria, affected clients, preservation and recovery. Ask Jesse about unresolved consequential choices. |
| 2. Independent worktree | Use **superpowers:using-git-worktrees** before writing the spec or implementation. Record base, lane and task-owned scratch. Preserve unrelated work. |
| 3. Written spec | In the lane, write scope, non-goals, behavior, recovery and a whole-journey test plan. Jesse approves before implementation. |
| 4. `/par` on spec | Freeze the specification and resolve evidenced findings. Revise and re-review affected requirements. |
| 5. Implement and test | Use **superpowers:test-driven-development**. Prove the full user journey across affected surfaces, including recovery and preservation. Update owning documentation. Read test scripts and verify actual output. |
| 6. `/par` on implementation | Review the immutable base/head diff, approved spec, amendments and behavior evidence. Include new files. Resolve legitimate findings with failing-then-passing tests. |
| 7. Simplify | REQUIRED: **simplify-code:simplify-code**. Preserve behavior and rerun affected checks. |
| 8. Shepherd PR | REQUIRED: **shepherd-pr:shepherd-pr**. Commit all intended changes. Batch each round's edits into one push and one review/CI wait. Satisfy base policy before final approval. |
| 9. Admin squash merge | Require current-head checks finished and green, matching review bodies and own per-commit findings settled under repository/Jesse policy. Use `gh pr merge <PR-URL> --admin --squash --match-head-commit <SHA>`. |
| 10. Verify and clean up | Query GitHub `MERGED`, merge SHA and intended content first. Archive required evidence, inspect retention notes, stop owned jobs, then remove owned disposable scratch, worktree and branches. |
| 11. Report | Report PR/SHA, behavior evidence, cleanup/preserved items. Deployment needs separate authorization. |

## PAR contract

Invoke installed `/par`. If direct loading is unavailable, read its instructions and execute its contract with two independent competing reviewers. Reviewer with most legitimate significant findings earns 5 points; inventions/inflated severity disqualify. Disclose adapted execution. Supply identical immutable inputs and inspect both reports.

## Common mistakes and return paths

| Common mistake | Required handoff |
|---|---|
| Reconstructed skill name | Load the exact identifier above. |
| `owner/repo#number` as PR operand | Use the PR URL returned by GitHub. |

**Red flags:**
- Scope/spec changes or amendments: Jesse approves, then re-review before implementation continues.
- Changed head: renew matching reviews/checks through shepherding.
- Two rejected attempts at one finding: stop and report.
- Merge timeout: reconcile before retry/cleanup.

Preserve designated Evener scratch, shared caches, unknown-owner files and unmerged work. Verify squash provenance, not ancestry alone, before disposal.

**Example:** Queue → restart → reconnect → send through agreed clients' real shared outbox and renderer. Component tests miss the journey.
