# /story-loop command — design

Massage harper reed's `/goal` "user-story-loop" prompt (canonical-CSV capability
loop) into a personal slash command that uses e2e scenario cards instead of a
CSV. Source prompt: https://gist.github.com/harperreed/c6e93f7eb70d83f5ff8110440a3a4992

## Goal

A `/story-loop` command that drives the current repo to a known-good state:
derive a verified, code-derived behavioral spec for every externally observable
capability, then iterate test → fix → re-test until everything is verified or
explicitly parked. Harper's CSV did two jobs — capability spec and status
tracker. The command splits those jobs across two artifacts: **scenario cards**
(spec) and a **status ledger** (tracker), and delegates testing mechanics to the
end-to-end scenario testing skill.

## Deliverable

- `~/git/dotfiles/.claude/commands/story-loop.md` — the command body.
- Manifest line `.claude/commands/story-loop.md` + `homedir-manager install`.

## Command design

### Invocation

`/story-loop` with optional `$ARGUMENTS` narrowing scope to named areas or
surfaces ("just the CLI surface"). No arguments = the whole repo. Works on the
current repo, like the original.

### Kept from harper unchanged (in spirit)

- Phase skeleton: Phase 0 plan → Phase 1 catalog → quality cycle; keep moving
  without stopping except at a real checkpoint.
- "Capability" = any externally observable behavior; the original's list of
  example capability kinds survives.
- Expected behavior derived from code/tests/fixtures/schemas/docs, code wins on
  conflict; never guess — log open questions instead.
- Status flow: `Spec'd → Tested-Pass | Tested-Fail → Fixed → Verified`.
  Promotion to Verified (resolving an ambiguity in the original): a
  `Tested-Pass` row promotes to Verified at iteration end if the pass came
  from genuine execution (not static-only) and no defect was logged against
  it; any row touched by a fix needs a fresh post-fix run to reach Verified.
- Defect types: Functional, Logistical, UX, Documentation, Testability,
  Environment, Unknown. Fix wave addresses Functional/Logistical/UX; the rest
  only when the fix is clear and needs no product decision.
- Checkpoint conditions: destructive/irreversible action, genuine product
  decision, user-only input, credentials with no safe local alternative.
- Strongest-practical-method ladder for choosing each capability's test method
  (real e2e → CLI → API/library harness → integration → existing unit tests →
  targeted new tests → static checks as last resort).
- Static-only verification is capped at Tested-Pass with a static-check note;
  it never reaches Verified unless execution is genuinely impossible and the
  project's nature makes static verification sufficient.
- Safety cap: a capability still failing after 3 full test/fix/re-test
  iterations is parked as Tested-Fail with root cause, attempted fixes,
  evidence, and recommended next action; report it plainly.
- Fresh-context self-checks at Phase 1 exit and each loop iteration end.
- Verify by running, not claiming; report real output; state skips and
  unknowns plainly.

### Artifact 1: scenario cards (the spec)

- One card per capability in `test/scenarios/` of the target repo, named
  `<area>-<nnn>-<slug>.md` (e.g. `auth-001-email-login.md`). The filename stem
  is the stable ID; IDs never change once assigned.
- Card format is the skill's card format, unmodified. Mapping from harper's
  CSV columns:
  - Actor + Story → one "As a … I want … so that …" line under
    **What this covers**, alongside the source refs (files/functions/tests
    that establish the behavior).
  - Expected behavior from code → `## Expected`, one falsification condition
    per assertion ("if you see X instead, the test fails").
  - Interface/entrypoint → the card's Pre-state/Steps.
  - Ambiguities → **Sharp edges** plus a ledger note.
- Cards and the ledger are committed to the target repo and remain after the
  loop exits as a living regression suite (deliberate deviation: harper's CSV
  had no afterlife).

### Artifact 2: the ledger (the tracker)

- Exactly one canonical file: `test/scenarios/LEDGER.md`, a markdown table:
  `ID | Card | Status | Test method | Defect type | Actual result | Notes / open questions`.
- The main thread is the sole writer. Runner subagents keep their own per-run
  workdir ledgers (a pre-existing skill concept); the main thread transcribes
  results into the canonical ledger. Never fork per-phase/per-area copies.

### Phase 0 — plan

Harper's project-shape detection list survives intact (languages, frameworks,
tooling, entrypoints, surfaces, workers, persistence, auth, integrations,
existing test infrastructure). Add the skill's preflight obligations: build
fresh from the code under test, hermetic instance (own HOME/port/state dir),
smoke check. Plan output: (a) inventory strategy, (b) ID/area scheme, (c)
per-surface test approach naming the skill's interface recipes
(web/CLI-TUI/computer-use), (d) what cannot be executed locally and how those
cases are handled without inventing results. Proceed once the plan holds.

### Phase 1 — catalog & card authoring

- Discovery subagents fan out by area/interface to inventory capabilities.
- Main thread assigns IDs and creates `Spec'd` ledger rows.
- Card-author subagents write cards under the skill's cards-only mandate:
  authors never modify product code, test code, or existing cards' assertions;
  a failing card plus root cause is a deliverable, not a fix.
- No design spec exists (the code is the source), so the skill's
  check-cards-against-spec script does not apply. The Phase 1 exit self-check
  is a fresh-context reviewer comparing the card set + ledger against the
  discoverable code surface, reporting omissions and unsupported claims.
- Exit Phase 1 only when every discoverable capability has a card and a row.

### Quality cycle — test → fix → re-test until clean

1. **Test.** Every card not yet Verified runs via disposable runner subagents
   dispatched with the skill's runner prompt template (hermetic workdir,
   evidence captured and re-inspected, per-assertion verdicts, one flake retry,
   never weaken/skip/reinterpret an assertion). Batch multiple cards per
   runner sequentially where sensible. No product/tool behavior changes during
   the Test step. Main thread updates ledger rows: Status, Test method, Defect
   type, Actual result, Notes.
2. **Fix.** Separate wave, after testing: root cause first (invoke
   systematic-debugging), fix the cause not the symptom, scope limited to
   logged defects, no unrelated features/refactors, no silent behavior
   changes. Card edits are allowed only when the card itself is wrong
   (executing the card tests the card) — justified in the ledger, never to
   make a failing assertion pass.
3. **Re-test.** Fresh runners re-run every card touched by a fix, same method
   where possible. Pass → Verified; fail → Tested-Fail with root-cause notes.

Exit when all capabilities are Verified and no open Functional/Logistical/UX
defects remain, or everything unresolved is parked under the safety cap.

### Skill references

The command defers card format, runner dispatch, interface recipes, evidence
discipline, and honesty rules to the skill by reference, naming it as
"e2e-scenario-testing (a.k.a. superpowers:agentic-end-to-end-testing)" so it
resolves against either the dotfiles copy or the plugin release. The fix step
references systematic-debugging. Nothing from the skill is inlined beyond the
one-line card-naming convention and the ledger schema, which are the command's
own contribution.

## Out of scope

- No changes to the e2e skill itself or the superpowers repo.
- No eval/test harness for the command (it's a personal prompt; first real run
  is the shakedown).
- Not shared back to harper in this pass — the command depends on superpowers
  being installed.
