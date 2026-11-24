# superpowers-docs plugin — design

**Date:** 2026-06-10
**Status:** complete design from an autonomous pass (Jesse in meetings all
day; "take a pass at all of this"). Two forks he answered live: **one
study-first skill** as the front door, and **the portfolio lives in the
index**. Every other fork I decided myself — each is marked ⚑ and collected
in "Decisions made in your absence" for review. Jesse then ordered
/par → implement → live-test on clipfan. **/par adversarial review done
(2026-06-10): two competing Opus reviewers, 10 distinct legitimate
findings, all fixed in place.** Reviewer A won on count (6 legit — incl.
the stderr/stdout false-safety, the two-skill-world carryover, the
validate-and-revise dispatch hole); Reviewer B found the single most
valuable bug (Critical: `${CLAUDE_PLUGIN_ROOT}` is NOT substituted in
skill content — the documented mechanism is `${CLAUDE_SKILL_DIR}`;
verified against the official substitution table). Both reviewers also
confirmed the docmaint/sentinel/index mechanism claims they attacked.
**Subsumes:** `maintaining-documentation` v1 (dotfiles skill, live) and the
`writing-documentation` v2 design (2026-06-09 spec, never built). Their law
corpus survives intact; their packaging does not. The v2 spec remains the
detailed design of record for the marketing/voice/brochure references.

## Goal

A standalone Claude Code plugin that owns a project's documentation the way
a good documentation department would: **study** the project and its
audiences, **decide** the doc portfolio with the human, **write** each doc
with profession-grade craft (tech pubs, comms, marketing), **verify**
adversarially that every claim cashes, and **maintain** it all as the code
moves. World-class is measured one way: named readers stop failing at named
moments. Pragmatic is enforced as law: rigor lives in checkable rules
applied at the point of writing — never in pipeline ceremony.

## The shape, and why (the anti-greenfield argument)

greenfield — Jesse's named cautionary reference — encodes rigor as
**ceremony**: 106 markdown files (~33k lines), a 7-layer pipeline with 7
gates each carrying 3-attempt remediation loops, 45+ named agent roles, a
mandatory ~50-directory workspace, and a read-every-line mandate. Each
quality concern became a layer, role, or artifact.

The other two references encode the same rigor as **law**:
elements-of-style distills a profession into ~18 testable rules plus one
heavy reference, in a plugin whose entire structure is `plugin.json` +
`skills/`; superpowers skills are disciplines — laws, gates, red flags,
rationalization tables — TDD'd against baseline failures. This plugin takes
the second path everywhere a choice exists. Concretely:

| greenfield's pattern | this plugin's law |
| --- | --- |
| 7 layers, 7 gates, 3× remediation | one loop; two human gates (classification — the standard-tier born-doc confirm is this gate fired at standard depth; and the batched portfolio/cast/voice confirm) |
| 45+ agent roles | agents only where independence matters: the adversarial verifier(s) |
| ~50-directory workspace per run | two artifacts per project (dictionary, index) + stamps; never a third |
| read every line | study scaled to the request (see Scaled study) |
| exhaustive coverage mandates | gaps are findings; portfolio sized to the project |

Two greenfield concepts survive, in leaner forms we independently built:
confidence-tagged provenance citations (ours: claims cite the enacting
surface; per-slide citation footers) and "don't abstract what you don't
own" (ours: the cross-repo cashing rule).

## ⚑ Name

**Plugin `superpowers-docs`; skill `documentation`** — invoked as
`superpowers-docs:documentation`. Family precedent: superpowers-chrome.
The skill name is the department, not an action; the description field
(triggers only, per CSO) does the routing work. Alternatives if you hate
it: plugin `docs` (short, collision-prone) or `tech-pubs` (misdescribes
the marketing channel). The dotfiles v1 skill keeps its name during
transition — no collision, since the plugin skill is namespaced.

## ⚑ Where it lives, and the dev loop

- **New repo `~/git/superpowers-docs`** (own repo, like elements-of-style;
  later listed in superpowers-marketplace with a github source).
- Local development: `claude --plugin-dir ~/git/superpowers-docs`, with
  `/reload-plugins` for non-SKILL.md changes (SKILL.md edits are picked up
  live). For a persistent local install: `/plugin marketplace add` a local
  marketplace path. No publication until the gating evals pass.
- Layout (verified against current plugin docs — only `plugin.json` lives
  under `.claude-plugin/`; everything else at root):

```
superpowers-docs/
  .claude-plugin/plugin.json      # name, description, version, author, license
  README.md                       # written by the plugin itself (see Testing)
  skills/
    documentation/
      SKILL.md                    # hub: law + dispatch + red flags + rationalizations
      references/
        portfolio.md              # readers × moments model, mis-address test, study levels
        audit.md                  # full audit (ported from v1)
        incremental.md            # routine re-check (ported from v1)
        write-path.md             # docs ride along with code changes (ported from v1)
        dictionary.md             # dictionary grammar + lifecycle + "document this term" (v1 + new entry point)
        new-docs.md               # birth flow for engineering docs (ported from v1)
        single-doc.md             # "validate and revise <doc>" (new; v1's deferred entry point)
        user-docs.md              # set design + per-doc craft (from v2 spec)
        marketing.md              # cast law + story law + BROCHURE.md flow (from v2 spec)
        voice.md                  # voice spec, four presets, slop tells (from v2 spec)
        brochure-design.md        # heavy visual reference (from v2 spec; MIT-attributed)
      templates/
        DICTIONARY-template.md    # ported from v1
        INDEX-template.md         # ported from v1, + Reader column
        BROCHURE-template.md      # from v2 spec
      scripts/
        docmaint                  # ported from v1 (see docmaint below)
```

- Skill text references its bundled files via `${CLAUDE_SKILL_DIR}` — the
  documented skill-content substitution ("the directory containing the
  skill's SKILL.md … for plugin skills, this is the skill's subdirectory
  within the plugin, not the plugin root"). docmaint is invoked as
  `${CLAUDE_SKILL_DIR}/scripts/docmaint`; references as
  `${CLAUDE_SKILL_DIR}/references/<name>.md`. This replaces v1's "invoke
  by absolute path under ~/.claude/skills" rule. (`${CLAUDE_PLUGIN_ROOT}`
  is NOT substituted in skill content — it exists only for hooks/MCP/LSP/
  monitor config strings; an adversarial review caught the spec's earlier
  claim to the contrary.)
- No commands, agents, or hooks at v1.0. The skill auto-triggers and can be
  invoked explicitly; a write-path PostToolUse nudge hook is a tempting
  future addition, listed as a non-goal now.

## Architecture: one loop, one skill

**Study → decide → write → verify → maintain.** Maintenance is the same
loop re-entered with a diff instead of a blank page. One front-door skill
(Jesse's call) whose first move is always study — scaled to the request —
then dispatch to a flow reference. Law lives only in the hub; flows add
process and never restate law (v1's proven structure).

### The front door

**Description (triggers only, no workflow summary):** Use when
documentation work comes up in any form — updating docs after code
changes, auditing docs against reality, writing user guides, tutorials,
READMEs, product overviews or HTML brochures, defining or disputing
terminology ("document this term"), revising one named doc ("validate and
revise X"), deciding what docs a project needs, or bootstrapping docs for
a project that has none.

### Scaled study (the pragmatism mechanism)

Study depth is proportional to the request — greenfield's fixed-cost
front-loading is the named failure mode.

- **Micro** — read the index and dictionary; no human gate. For: document
  this term; validate-and-revise one doc; write-path ride-along;
  incremental re-checks.
- **Standard** — micro, plus the portfolio rows the work touches; human
  gate only if a new doc/row is born. For: a new engineering doc; one new
  user doc into an existing set.
- **Full** — the complete portfolio pass: enumerate real readers (user,
  operator, contributor, adopter) × moments (evaluate, get started,
  accomplish, recover, understand, extend); map existing docs into the
  matrix; name gaps, excess, and **mis-addressed docs** (a doc whose
  performing reader is not its addressed reader); confirm as one batch
  decision with the human. For: bootstrap; full audit; user-docs set
  design; marketing (the cast/voice confirm rides the same gate); "what
  docs do we need?"

### Dispatch (hub table: situation → reference, study level)

| Situation | Reference | Study |
| --- | --- | --- |
| No index / no docs / "set up docs" / "what docs do we need?" | portfolio.md → then per-genre flows | full |
| Full audit: "docs are out of date", pre-release, untrusted set | audit.md | full |
| Routine re-check of audited docs | incremental.md | micro |
| Just finished code work; docs ride along | write-path.md | micro |
| "document this term X"; term disputes; exceptions | dictionary.md | micro |
| "validate and revise <doc>" — one named doc | single-doc.md | micro |
| New engineering/contributor doc | new-docs.md | standard |
| User-facing docs (guide, tutorial, how-to, reference) | user-docs.md | standard (set redesign: full) |
| Adopter-facing: BROCHURE.md, brochure.html, README intro, positioning | marketing.md | full |

The two formerly deferred v1 entry points — "document this term" and
"validate and revise" — are first-class rows. single-doc.md is small by
design: classify (from the index), re-verify that doc's claims under the
rubric, fix what's determinate, interview the rest, one independent
verifier, restamp.

**Dispatch precedence (closes the genre/single-doc collision):**
"validate and revise <doc>" always *enters* through single-doc.md, which
reads the doc's Reader cell first. `contributor`/engineering docs it
handles fully at micro study. A `user` or `adopter` doc **escalates**:
the genre's craft law applies, so single-doc.md hands off to user-docs.md
or marketing.md and the study level rises to that genre's. Without this
rule, "validate and revise our getting-started guide" would match two
rows and the cheap path would silently skip voice/story/cast law. And the
universal v1 gate is restated on this new entry point: **no confirmed
index → bootstrap first** (portfolio.md / audit Phase 0) — micro study
cannot run against an index that doesn't exist.

## Law corpus (hub law)

Carried whole; the build adapts text from the v1 hub and the v2 spec
rather than re-deriving it. One-line inventory with provenance:

1. **Classify before you edit** (evergreen vs. point-in-time; the
   never-skip human gate; persisted in the index) — v1.
2. **Reader, moment, job** (a doc with no named reader-in-a-moment is not
   written) — v2, now governing the whole loop.
3. **Claims must cash** (capability claims cite the enacting surface;
   outcome claims need measurements; **a surface cashes a claim for a
   reader only if that reader performs it**; cross-repo surfaces cited by
   name and only if they exist; future work is roadmap-labeled) — v1+v2.
4. **Verify the verb, not the noun** — v1.
5. **Show real things** (every command/output/number was produced, never
   imagined) — v2.
6. **Honesty floor** (superlatives need measurements; limitations stated;
   who-it's-NOT-for stated; costs stated to whoever bears them;
   "it's just marketing" is the rationalization this plugin exists to
   kill) — v2.
7. **Auto-fix rubric** (mechanical, determinate, local, history-checked —
   else interview; counts, line numbers, negatives, semantics always
   interview) — v1.
8. **Two artifacts + stamps; never a third** (dictionary, index; stamp =
   independently verified, with the deferred-claims discipline) — v1.
9. **Prose law** (elements-of-style where available; resolved project
   voice; marketing elevates Strunk 12/11/13 + "Interesting") — v2.
10. **Story law** (problem beat load-bearing and cashable; one controlling
    idea; every beat turns; structure from the storytellers' canon, facts
    from the repo) — v2 final round.
11. **Voice law** (per-project `## Voice` in the dictionary; four presets;
    slop-tell ban; exemplar test; founder preset requires a real
    interview) — v2.
12. **Pragmatism law** (name the reader or don't write it; gaps are
    findings, not mandates; adopt existing structures; bounded
    maintenance; **portfolio sized to the project** — a 300-line utility
    earns a README, not a doc suite) — v1, extended.

The hub also carries the merged red-flag list and rationalization table
from v1 and the v2 seeds, plus baseline findings from the new RED runs
(Testing). Hub token budget: like v1, it knowingly exceeds the <500-word
skill target — it is a hub-law skill; budget discipline is structural (law
once in the hub, process in flows, heavy reference split out).

## The index, extended (portfolio lives here — Jesse's call)

Schema gains one column: `Doc | What | Reader | Class | Owns`.

- **Reader values:** `user`, `operator`, `contributor`, `adopter`, or a
  `+`-joined combination for genuinely sectioned docs (a README is
  `contributor+user+adopter`); `—` for point-in-time rows (archives are
  records, not addressed). The mis-address test stays **agent judgment —
  no tooling**: the Reader cell records the *addressed* reader; the agent
  checks whether the doc's surfaces are ones that reader actually
  performs, and a contradiction is a finding.
- **Decided gaps** persist as an HTML comment block below the fenced
  table — same mechanism as the existing "Excluded from this index"
  comment (precedent: superpowers-cloud-server `docs/INDEX.md`). Example:
  `<!-- Decided gaps: no tutorial (single-operator project, 2026-06-10);
  no API reference (no public API). -->` This is what stops a future full
  study from re-litigating settled "we don't write that here" decisions.
- **Migration:** existing governed repos (cloud-server) gain the Reader
  column at their next full-study flow (audit or portfolio pass), as part
  of that flow's index maintenance — never as a standalone chore.
- Two-artifact law intact: no new file.

## docmaint (ported, minimally changed)

Moves to `skills/documentation/scripts/docmaint`; invoked via
`${CLAUDE_SKILL_DIR}`. The plugin owns it now, so changes are allowed —
and kept to exactly one: **the index parser becomes header-aware** (reads
the column order from the header row) so the Reader column — and any
future column — doesn't break `stale`'s Owns-glob diffing. `scan`,
`stamp`, stamp grammar, GENERATED_MARKERS, and the exclusion rules are
unchanged. Per-project artifacts produced under v1 remain valid without
edits; stamps don't name the skill.

One wording change downstream: the brochure sentinel becomes
`<!-- do not edit; generated by the superpowers-docs documentation skill
from docs/BROCHURE.md @ <sha> -->` — still containing both
GENERATED_MARKERS strings ("do not edit", "generated by"), so the
exclusion behavior is identical.

**Regeneration under the merged skill.** v2's accepted cost — "the
brochure may trail BROCHURE.md between invocations of this skill" — was
rationalized by a skill boundary (the *maintaining* sibling legitimately
didn't render). The merge abolishes that boundary, so the rule changes:
**any flow that restamps BROCHURE.md — write-path, incremental, and audit
included — runs marketing.md's sentinel check (brochure sentinel SHA vs.
BROCHURE.md stamp SHA) and re-renders on mismatch.** One skill owns both
artifacts now; a restamp without the re-render check is a defect, not an
accepted cost.

## Expertise channels (judgments, not personas)

Each profession enters as named canon distilled to checkable rules,
enforced by the same independent verifier as claims — the Strunk pattern.
No roleplay prompts anywhere.

- **Tech pubs** (the deepest channel; portfolio.md + user-docs.md):
  Diátaxis (Procida) for doc types serving journeys; minimalism (Carroll,
  *The Nurnberg Funnel*) — checkable as: every user doc opens with the
  reader's task, not the system; concepts appear at point of need, not in
  front matter; error/recovery info lives beside the step that fails (v2
  already encodes the last). Terminology control — the dictionary IS a
  tech-pubs artifact (controlled vocabulary). Progressive disclosure —
  reference depth never blocks the first-success path.
- **Comms** (marketing.md + user-docs.md): the cast law (audiences are
  cast members with distinct proofs and CTAs), stakeholder anticipation
  (the comms-leader voice's "your security review will ask" move),
  register signposting at audience shifts.
- **Marketing** (marketing.md): positioning (who it's for and NOT for, as
  a feature), the story law, claims-must-cash + honesty floor as the
  discipline that makes the rest publishable.

## Genre flows: provenance and deltas

| Reference | From | Delta vs. source |
| --- | --- | --- |
| portfolio.md | v2 spec §doc-portfolio | now a first-class flow (study levels live here); writes the Reader column and decided-gaps block; renames v2's `evaluator` reader to `adopter` (matching the Reader enum and v2's own marketing-flow term) |
| audit.md, incremental.md, write-path.md, new-docs.md | v1 verbatim-ish | docmaint path via `${CLAUDE_SKILL_DIR}`; index work includes Reader; restamping BROCHURE.md triggers the sentinel re-render check (below) |
| dictionary.md | v1 | + "document this term X" as a named entry point |
| single-doc.md | new (v1's deferred #2) | bounded one-doc verify-and-revise |
| user-docs.md | v2 spec | craft content unchanged; cross-skill handoffs rewritten intra-skill (see note below) |
| marketing.md | v2 spec | BROCHURE.md naming; story law included; sentinel wording above |
| voice.md, brochure-design.md | v2 spec | unchanged (brochure-design keeps MIT attribution @ 3657bf1) |

The v2 spec's full text for these flows is design-of-record **for craft
content only**. That text was written for a two-skill world; every
cross-skill handoff in it ("Cross-ref → maintaining-documentation",
"delegated to maintaining-documentation's new-docs flow", "their flows
restamp without re-rendering") is rewritten at build time as an
intra-skill reference (→ new-docs.md / audit.md / this hub) — the sibling
it names no longer exists. The craft is carried; the routing is not.

## Migration from the dotfiles skills

1. Build the plugin; run it under `--plugin-dir` only.
2. Gating evals pass (below).
3. Retire dotfiles `maintaining-documentation`: remove the manifest entry,
   `homedir-manager install`, keep the dotfiles history (specs/plans stay
   as the family's archive). v2 `writing-documentation` is never built
   standalone — subsumed before birth.
4. Governed repos need nothing: artifacts and stamps are
   skill-name-agnostic; the Reader column arrives via their next full
   study.

During the overlap window both v1 (personal skill) and the plugin can
load; namespacing keeps them distinct. **A repo migrates wholly:** once the
plugin's full study lands the Reader column, only plugin flows run there.
This invariant is the ONLY safety: v1's `parse_index` is strict-positional
(`len(cells) != 4` → row skipped), and on a 5-column index its warnings go
to **stderr** while the `stale` **stdout worklist comes out empty** — which
a consuming v1 flow reads as "nothing stale," a silent false-clean across
the whole evergreen set, not a loud failure. Keep the window short.

## Testing and eval (writing-skills Iron Law applies)

No skill text without a failing test first; baselines run via
session-driver workers, findings captured verbatim into the hub's
rationalization table.

**RED baselines (without the plugin):**
1. Brochure for superpowers-cloud-server (v2's scenario — expected:
   fabricated output, uncashed claims, role blending, voice-from-nowhere).
2. Getting-started for cloud-server (v2's — expected: imagined output,
   contributor path sold as user path).
3. **Study baseline (new):** "Set up documentation for this project" on a
   small repo with no docs — expected: Diátaxis-boilerplate four-of-each,
   docs no reader asked for, no human gate, unsized portfolio.
4. **Ride-along baseline (new):** a code-change session ending with "update
   the docs" — expected: unbounded rewrite or missed owning docs, no
   verification. ("Stamps without verifiers" is NOT an expected RED
   failure — a bare agent has no stamp concept; that assertion lives in
   GREEN: with the plugin, no stamp lands without an independent
   verifier. Caveat to record: v1 is globally deployed during
   baselining; if it fires and disciplines a run, record that run as
   port-must-not-regress evidence rather than RED.)

**GREEN:** same scenarios with the plugin; plus application probes — the
term entry point routes to dictionary.md; "validate and revise X" stays
bounded to X; "document this module's internals" routes to new-docs.md
(internal routing now — there is no second skill to route out to); the
portfolio gate fires and is sized to the project; claims carry citations;
voice passes banned-list + exemplar tests.

**Gating live evals:**
- **cloud-server delta:** a full study on the already-governed repo —
  Reader column lands, mis-addresses surface (we know of real ones: the
  protocol-schema.md stale client-skill claim), brochure + getting-started
  produced under the law.
- **Dogfood bootstrap:** the plugin documents **itself** from zero — its
  README, index, dictionary born through its own portfolio flow. If the
  result is overbuilt, the pragmatism law failed its own test.
- superpowers repo: follow-up, never gating (needs its own bootstrap
  first; same reasoning as v2).

**Validation already in hand:** the 2026-06-09 dry runs (three-act/cast
structure, claims-from-stamped-docs sourcing, four voice presets, citation
footers) — `/tmp/cloud-build-brochure-dryrun/`. Design evidence, not test
fixtures.

## Pragmatism and non-goals

- No multi-harness support at v1.0 (Claude Code only; superpowers'
  porting guide exists if that ever changes).
- No commands, agents, hooks, or MCP at v1.0. No generator scripts beyond
  docmaint; the agent renders brochures from prose standards.
- No PPTX/PDF/social outputs; no light-mode palette (carried from v2).
- The plugin never edits generated/foreign-owned docs (root ABOUT.md
  stays maintaining-project-map's).
- Marketplace publication is explicitly out of scope until gating evals
  pass and Jesse opts in.

## ⚑ Decisions made in your absence (review these)

1. **Name:** `superpowers-docs` / skill `documentation` (alts: `docs`,
   `tech-pubs`).
2. **Repo:** new `~/git/superpowers-docs`, own git history (alt: a dir in
   an existing repo first).
3. **Scaled study** (micro/standard/full) as the front door's pragmatism
   mechanism — new design, no prior approval.
4. **Reader column values** incl. `+`-joined combos and `—` for
   point-in-time rows; decided-gaps as an index comment block.
5. **docmaint may change now** (plugin owns it), bounded to the
   header-aware index parser.
6. **single-doc.md and the term entry point** promoted from "deferred" to
   v1.0 scope — they're small and they complete the dispatch story.
7. **Dogfood bootstrap as a gating eval** (the plugin documents itself).
8. **Migration order** (build → evals → retire dotfiles v1) and the
   short overlap window.

## Revision round 2026-06-11 (Jesse's review of the first live brochure)

Owner review of the clipfan deck (RED 6 in the plugin's eval record)
revised the marketing genre, built and pushed @ superpowers-docs a536cbe:

- **The rendered artifact is a brochure site, not a deck**: one
  scrolling product page at `docs/index.html` (GitHub Pages "deploy from
  branch /docs" convention), zero JavaScript, repo-relative assets
  allowed, citations per section, same sentinel/regeneration contract.
  The keynote-deck standard is retired (git history keeps it).
- **Voice preset 5, "the publication writer"** — benefit-first plain
  English for a less technical reader; hard bans: contrastive negation
  (zero budget) and em dashes in copy. Now the default for adopter
  artifacts; the engineer remains the default elsewhere.
- **elements-of-style vendored into the plugin** (public domain) and
  REQUIRED reading before drafting adopter copy — the "where available"
  escape is gone for this genre.
- **Story law tightened**: the problem beat stands in its own section,
  stated and left unresolved there (the deck's slide 2 mixed problem and
  promise — the documented failure).
- **Gate tightened** (from GREEN 5's finding): a broad instruction is
  not the batch confirm; the gate asks voice/cast/plan even when scope
  arrives pre-authorized.

## Open questions (deliberately left for the talk)

- Marketplace timing and whether superpowers core ever absorbs this
  plugin (your "(these skills will end up as *part* of superpowers)" vs.
  today's "new claude code plugin" — I read today's as the operative
  call: standalone in the family marketplace, graduation only if earned).
- Whether a write-path nudge hook (PostToolUse on code edits) is wanted
  once the skill proves out — deferred, listed so its absence is a
  decision.
