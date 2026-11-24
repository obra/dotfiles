# writing-documentation skill — design

**Date:** 2026-06-09 (final write-up after five design rounds + dry-run validation)
**Status:** buttoned up 2026-06-10 and preserved as **input material**: Jesse
redirected the family toward a reimagined docs-creation-and-maintenance
*plugin* (world-class but pragmatic; marketing, comms, and tech-pubs
expertise), so this spec no longer feeds writing-plans directly. Final
same-day additions: the story law (storyteller canon), the
reader-performs-surface rule, the doc-portfolio foundation, and the
BROCHURE.md rename.
**Sibling:** `maintaining-documentation` (one writes docs into existence; the other keeps them true)

## Goal

A skill for writing documentation aimed at audiences beyond the code:
user-facing docs (getting-started guides, tutorials, how-tos, reference) and
honest marketing material (what the product is, who it's for, how to use it —
including a self-contained HTML brochure). It routes by reader, enforces that
every claim is cashed by reality, writes in a configurable per-project voice,
and hands its outputs to maintaining-documentation's machinery so they stay
true.

## Where it lives

- **Now:** `~/git/dotfiles/.claude/skills/writing-documentation/`, manifest
  entry, deployed via homedir-manager — same mechanics as
  maintaining-documentation v1. Prove it locally first.
- **Destination:** the superpowers plugin, together with
  maintaining-documentation. Migration is explicitly out of scope here; write
  the skill to superpowers house style (writing-skills discipline, CSO
  description, token budgets) so graduation is a move, not a rewrite.
- **Gating eval target:** superpowers-cloud-server (already under
  maintaining-documentation governance). The superpowers repo is a follow-up
  target — it needs a maintaining-documentation bootstrap pass first (itself
  a useful v1 eval), so it never gates this skill's acceptance.

## Identity and dispatch

**Name:** `writing-documentation`.

**Description (triggers only, per CSO):** Use when creating documentation or
deciding what docs a project needs — what-is-this / who-is-it-for product
descriptions, README introductions, HTML brochures or product overviews,
getting-started guides, tutorials, how-tos, user reference, or marketing copy
that must stay honest.

**Dispatch — route by reader, not doc type.** The hub's first question (who
is the reader?) is also its router:

| Who is the reader? | Flow |
| --- | --- |
| Contributor, maintainer, or agent working on this codebase | Cross-ref → maintaining-documentation (its new-docs flow owns engineering docs; never duplicated here) |
| Someone **using** the product | `references/user-docs.md` |
| Someone **deciding whether to adopt** the product | `references/marketing.md` |

Mixed documents decompose: a README serves all three readers in different
sections, and each section gets the flow its reader demands. The dispatch
rows are hard gates, as in v1: read the flow file before doing anything.

## Hub law

Law lives only in the hub; flow files add process and never restate it.

1. **Reader, moment, job.** Name the reader as a person-in-a-moment ("a
   developer who just found the repo, deciding in 30 seconds whether to keep
   reading") and what they can DO when the doc has done its job. A
   demographic is not a reader; a doc with no job is not written. This
   single law gates every flow and routes the dispatch — and an invented
   persona can't survive it, because a fictional reader has no checkable
   job.
2. **Claims must cash.** A *capability* claim ("it does X") enters a doc
   only citing the surface that enacts X — verify the verb, exactly as in
   maintaining-documentation. An *outcome* claim ("you'll save hours") needs
   a real measurement, or gets rewritten as the capability claim it gestures
   at ("automates X so you don't do it by hand"). Rhetoric may amplify
   verified claims; it never substitutes for them. Future work is cut or
   labeled roadmap. **A surface cashes a claim for a reader only if that
   reader is the one who performs it** — operator plumbing cannot cash a
   user-path claim (the cloud-server dry run surfaced exactly this: an
   onboarding doc addressing end users with machine-enrollment commands
   only an operator runs). When the addressed reader's real surface lives
   in another repo (a client, a plugin), the claim cites that named
   external surface — and only if it exists today; otherwise it is
   roadmap.
3. **Show real things.** Every command, output, number, and demo in an
   audience doc was produced from the project as it is — run, not imagined.
   Fabricated example output is the signature failure of this genre.
4. **Honesty floor.** Superlatives need measurements. Comparisons are dated
   and fair. Limitations are stated. Who it's NOT for is stated — that's a
   feature of good positioning, not an admission. Costs are stated to
   whoever bears them: never sell one reader's burden as another reader's
   benefit, and never hide it from the one who carries it. "It's marketing,
   everyone inflates" is never an exemption; it is the rationalization this
   skill exists to kill.
5. **Born conformant, by reference.** Everything this skill writes is an
   evergreen doc and goes through maintaining-documentation's machinery —
   dictionary terms, index row with Owns globs, scan, independent
   verification, stamp. This skill never re-implements that machinery.

**Prose law (hub note, not numbered law):** the writing step in every flow
uses `elements-of-style:writing-clearly-and-concisely` where available, and
writes in the **resolved project voice** (see Voice below): the target
project's `## Voice` section in `docs/DICTIONARY.md` if present, else a
preset from `references/voice.md` (default: the engineer). The marketing
flow elevates four Strunk rules to voice law (see below).

## Preconditions

- The target project is under maintaining-documentation governance: a doc
  index with a confirmed `Class` column exists. If not, run that skill's
  audit Phase 0 / bootstrap first.
- Dictionary conformance applies where a dictionary exists; its absence does
  not block writing (new recurring terms still route through
  maintaining-documentation's dictionary flow when one exists).

## The doc-portfolio foundation

The family's third leg: v1 keeps docs *true*, this skill writes them
*well*, and the portfolio model says **which docs, for whom**.
`references/doc-portfolio.md` defines it, Diátaxis-grounded: enumerate the
project's real readers (user, operator, contributor, evaluator) and
moments (evaluate, get started, accomplish a task, recover, understand,
extend); map the existing docs into that matrix; name the gaps and the
**mis-addressed docs** — a doc whose performing reader is not its
addressed reader. (cloud-server's onboarding.md was exactly this:
operator-layer machine enrollment wearing the product-onboarding label —
invisible to v1, because claims-vs-code verification never checks
reader-vs-surface.) Both batch gates consult it: the user-docs set plan
and the marketing cast confirm. A full portfolio-audit entry point ("are
these the right docs at all?") is deferred alongside v1's deferred entry
points — and is a likely first-class flow in the plugin reimagining.

## Flow: `references/user-docs.md`

**Set-level first.** (Doc birth itself is delegated to
maintaining-documentation's new-docs flow, as in the marketing flow; this
flow owns the set design and the craft standards layered on top.)

1. Inventory the existing user-facing surface.
2. Name the reader journeys: evaluate → first success → routine use →
   troubleshoot/recover.
3. Propose a doc-set plan mapping docs to journey stages — one doc, one job.
   Doc types are Diátaxis-informed (tutorial = first success, how-to = task,
   reference = lookup, explanation = concepts) but serve the journeys, not
   the taxonomy: a project gets the docs its journeys need, never
   four-of-each.
4. **Confirm the set with the human as one batch decision** (the same gate
   shape as v1's classification confirm) — together with the resolved voice.
   Only then write.

**Per-doc craft standards:**

- Lead with what the reader gets; the job statement shapes the first
  paragraph.
- Tutorials are measured by time-to-first-success.
- Real commands with real, verified output (hub law 3).
- Prerequisites explicit, up front.
- Failure modes and recovery live next to the commands that fail.
- Project terms follow the dictionary but are defined for outsiders on
  first use. A user doc that must *mention* a deprecated or renamed term to
  orient outsiders ("formerly called X") uses the dictionary's `[manual]` /
  exception machinery rather than tripping scan.
- A user doc never points a user at internal material — "see the design
  doc" is a defect.

**Revision is owned elsewhere:** user docs are evergreen index rows with
Owns globs, so write-path and incremental flows maintain them. This flow
re-enters only for redesigns ("our getting-started guide sucks" reruns the
set-level pass).

## Flow: `references/marketing.md`

**Architecture: markdown source of truth, HTML as designed rendering.**
Modeled on the artifact class of microsoft/amplifier-bundle-stories (their
product overview is a single-file keynote-style HTML deck), but with claims
discipline their engine lacks. We copy the artifact, not the machinery.

**The cast law.** The "deciding whether to adopt" reader is a **cast**, not
a person: the **user** (hands on keyboard; receives the capability) and the
**owner/operator** (deploys it; carries the cost and the risk). They are
different people — and when they're the same human, they're different
moments, which hub law 1 already treats as different readers. The
**contributor** is not this artifact's audience (at most a one-line pointer
to the engineering docs). One act per reader-moment; register shifts
signposted, never interleaved. Each audience gets its own proof type (user:
the experience, real commands, demos; owner: mechanisms and invariants) and
its own exit (CTA). Strategic order is user-first: Acts I–II create a
champion; Act III is the trust brief that champion hands their platform
owner. For a server-side component whose end-user surface lives in a
client repo, the user act cites that external surface or is labeled
roadmap — hub law 2's performer rule decides.

**The story law** — the cast law's narrative complement, grounded in the
storytellers' canon the way the prose law is grounded in Strunk.
Structure comes from people who build stories for a living; facts still
come only from the repo. The canon, and what each piece grounds:

- *Building a StoryBrand* (Miller): the customer is the hero, the brand
  is the guide. Already encoded as Act I's user-as-subject rule; the
  canon adds the test (who is the subject of the sentences?) and the
  warning (a brand that plays the hero loses the reader).
- *Resonate* (Duarte): great talks oscillate between **what is** and
  **what could be** until the gap resolves. Acts contrast states; they
  never just stack features.
- The strategic-narrative five (Raskin): name the undeniable shift in
  the world, show stakes, tease the promised land *before* the product,
  present capabilities as gifts for getting there, then give evidence
  you can deliver. The owner act is the evidence move.
- *Made to Stick* (Heath): the concrete detail *is* the persuasion —
  the canon behind hub law 3.
- McKee's beat test: every scene turns a value; a scene that turns
  nothing is cut.

Three checkable rules fall out:

1. **The problem beat is load-bearing.** Act I opens on the named
   status-quo cost, before the promise. The cost must cash like any
   claim — something a cast member actually bears today, citable; a
   manufactured villain is a slop tell, not a story.
2. **One controlling idea.** Write the artifact's thesis in one sentence
   before composing. Every slide advances it; a slide that doesn't is
   cut or moved to another doc.
3. **Every beat turns.** Each slide changes the reader's state —
   ignorance to knowledge, doubt to trust, want to path. A slide that
   leaves the reader where it found them is cut.

- **`docs/BROCHURE.md`** — the canonical positioning document, governed end to
  end (index row, Owns globs, scanned, verified, stamped). (Named
  BROCHURE.md, not ABOUT.md: repo-root `ABOUT.md` is already taken in
  this ecosystem by the maintaining-project-map skill — machine-
  maintained, catalog-audience, its own do-not-edit regime; two ABOUTs
  with different owners is a trap, and BROCHURE.md → brochure.html pairs
  by name.) Its **birth is
  delegated** to maintaining-documentation's new-docs flow (hub law 5); this
  flow adds only the genre-specific steps on top (section shape, voice,
  brochure render). Sections mirror the cast: one-sentence what-it-is a
  stranger parses; **What you get** (user: the transformation); **Using it**
  (user: the experience, the first-success path on an existing deployment);
  **Running it** (owner: how it works, what you deploy and operate); fit —
  who it's for and not for, by role; limitations, **each tagged by who bears
  it**; getting started, **two paths** (user: enroll and push; owner: the
  deploy guide). Capabilities everywhere carry their cash (the
  feature/surface citation). **Owns rule:** the enacting surfaces of the
  capabilities it names — not the whole tree. Re-triggering on real feature
  change is intended behavior: drift matters most in marketing claims.
  Default name `docs/BROCHURE.md`, overridable to fit project conventions.
- **`docs/brochure.html`** — a self-contained HTML deck the agent renders
  from BROCHURE.md's verified claims. Composition is design work; content is
  inherited — a capability appears in the deck only if BROCHURE.md carries it
  verified. The arc is **three acts plus a close**, one register each:
  **Act I — what you get** (user; opens on the problem beat, then the
  transformation; the user is the hero and the subject of every verb;
  zero architecture). **Act II — using it** (user;
  experiential; real commands and the first-success path). **Act III —
  running it** (owner; engineering register; now the system may be the
  subject: isolation, credentials, control surfaces, visibility,
  what-you-operate, limits by bearer). **Close: doors** — a CTA per
  audience (use it / run it / try it first), plus a one-line contributor
  pointer. "How it works" is a trust argument and lives in Act III, never
  in the pitch. A single artifact stays in **one voice** throughout — acts
  change audience, not speaker. The file opens from `file://`, attaches,
  and presents.
- **Generated-file sentinel.** The brochure's first line is
  `<!-- do not edit; generated by the writing-documentation skill from
  docs/BROCHURE.md @ <sha> -->`. The wording is load-bearing: it contains both
  marker strings docmaint's generated-file exclusion actually recognizes
  ("do not edit", "generated by"), so `scan` skips the brochure and v1's
  scope law applies as written. `<sha>` is the SHA from BROCHURE.md's stamp
  line — an **equality cursor**, not a content hash (the stamp records
  review-state HEAD; the stamp edit itself rides uncommitted, so the SHA
  names the code state the claims were verified against, nothing more).
- **Regeneration rule — owned by this skill, honestly.** Re-rendering is
  writing-documentation's job: every invocation of this flow that touches
  or finds BROCHURE.md compares the brochure's sentinel SHA to BROCHURE.md's
  stamp SHA and re-renders on mismatch. maintaining-documentation's flows
  restamp BROCHURE.md without re-rendering — their passes are claim-bounded
  tool invocations that never read EOF comments, and we do not pretend
  otherwise. The template still plants a one-line pointer comment next to
  BROCHURE.md's stamp as a breadcrumb for whoever reads the file, but the spec
  does not rely on it. Accepted cost: the brochure may trail BROCHURE.md
  between invocations of this skill; the sentinel mismatch makes that state
  detectable, never silent. No docmaint change.
- **README intro — hook plus link, never a restatement.** The README intro
  carries BROCHURE.md's one-sentence what-it-is (verbatim — BROCHURE.md
  owns it) and a pointer to BROCHURE.md / brochure.html. It never
  restates the capability list: a
  restated list is exactly the substantive duplication v1's corpus pass
  (audit Phase 4) exists to find. README ownership and its index row stay
  with v1, untouched.
- **No index row for brochure.html** — it is generated and non-markdown.
  BROCHURE.md's row covers the claims. (Asymmetry note: without the
  generated-file sentinel above, `scan` — which sweeps all tracked files,
  not just markdown — would still reach the brochure; the sentinel is what
  keeps it out.)

**Strunk voice law (elevated, applies on top of the resolved voice):**

- Rule 12 — definite, specific, concrete: the antidote to vapor.
- Rule 11 — positive form: the antidote to over-hedged honesty that reads
  as mush.
- Rule 13 — omit needless words.
- "Interesting" (Section V) — instead of announcing that the product is
  exciting, make it so. The anti-hype rule in one sentence.

## Voice: per-project, configurable, with four presets

Honest claims are necessary but not sufficient: an artifact can be perfectly
honest and still sound like every launch page since 2019 — voice-from-nowhere
is what makes AI marketing read as slop. Voice is therefore a first-class,
configurable input to both flows.

**Where it lives.** A project's voice is an optional `## Voice` section in
`docs/DICTIONARY.md`. The dictionary is already the project's
language-of-record (words, names, divergences); voice is the sentence-level
layer of the same artifact. docmaint's parser keys only on `## Terms`,
`## Names`, and `## Exceptions` (`parse_dictionary`), so a `## Voice`
section is inert to the tool — **no docmaint change, no third artifact**.
Bootstrapping a `## Voice` section for a project that lacks one is a
dictionary edit (v1's dictionary flow, with this skill supplying the draft
from the project's existing best prose).

**The voice-spec format** (what a `## Voice` section contains — it may
start from a preset by name and override fields):

- **Speaker** — who is talking ("the engineer who built it, to a peer").
- **Address** — how the reader is called; person policy for the maker.
- **Register** — e.g. plain technical prose; the fact carries the
  excitement, the sentence stays calm.
- **Humor** — policy and budget (e.g. dry, at most one per artifact, never
  winking).
- **Banned** — project-specific additions to the default slop-tell list.
- **Exemplars** — 3–5 sentences from the project's own best writing. This
  is the enforcement instrument: the verifier's test is *"would the person
  who wrote these write this line?"*
- **Look** — visual knobs the brochure render reads: accent color, density
  (`informative` — the default card/step-grid style — or `sparse`, one idea
  per slide, mapped from the adapted standard's two styles). Mode is
  dark-keynote for now; a light palette is future work, listed so the
  knob's absence is a decision, not an accident.

**Resolution and confirmation.** Project `## Voice` → else a preset from
`references/voice.md` (default: the engineer). The resolved voice is
confirmed with the human at the same batch gate as the cast/doc-set plan.

**The four presets** (full text in `references/voice.md`; each was
validated by rendering the complete cloud-server dry-run brochure in it —
same claims, same citations, voice the only variable). They span the four
proof types:

1. **The engineer who built it** *(default)* — proof by **mechanism**.
   Speaker: the builder, to a peer. Flat declaratives; mechanism first; the
   fact carries the excitement. Humor: dry, ≤1, load-bearing.
   *"Reclaim the box and the nonce dies with it."*
2. **The comms leader** — proof by **benefit-with-mechanism**. Speaker: a
   communications professional who believes the product and respects the
   audience; anticipates the reader's *stakeholders* (their security
   review, their boss). Benefit-led, but every benefit immediately cashed —
   "which means" is the signature move. Extra rule: an aspiration may
   appear only labeled as one.
   *"A compromised box yields a dead token, not your key."*
3. **The teacher** — proof by **demonstration**. Speaker: an experienced
   guide beside a newcomer. Short sentences, one idea each; says what
   you'll see before you see it; reassurance placed exactly at failure
   points; analogies allowed as teaching tools (distinct from drama
   metaphors). Extra rule: never claim an experience the reader can't
   immediately verify. The natural Act II / user-docs voice.
   *"The worker pauses until you answer."*
4. **The founder** — proof by **lived experience**. Speaker: the person who
   built it, first person singular, opinionated; concrete scenes; opinions
   stated as opinions. **Extra rule, load-bearing:** first-person
   statements are biographical claims — they must be *true of the actual
   maker*, gathered by interview, never invented. The most engaging preset
   and the most dangerous; it is where AI fabricates a life. Renders
   without an interview carry a visible "placeholders pending maker
   interview" note.
   *"I was treating my laptop like a hospital ward."*

A considered-and-rejected fifth, the *skeptical reviewer*: first-party
ventriloquism of your own critic is manipulation-adjacent, and the
limitations-by-bearer sections already deliver that candor structurally,
where it's verifiable.

Presets pair naturally with acts (comms shines in Act I, teacher in Act II,
engineer in Act III) — but a single artifact stays in one voice; the act
structure changes audience, not speaker.

**The slop-tell list** (default Banned; `references/voice.md` carries it):
stacked imperative-fragment headlines; X-not-Y reversals beyond one per
artifact; hype vocabulary (unleash, blazing, effortless, seamless, magic,
revolutionize, game-changing, "the future of") — and the product name used
as a hype-noun (a family literally named Superpowers does not get to sell
"superpowers"; names are exempt as names, not as metaphors);
rhetorical-question headers; manufactured drama metaphors where the literal
fact is stronger; sentimental closers; symmetry compulsion (three equal
cards when the content has two or four natural parts); "Welcome to / Meet /
Introducing" outside an actual launch.

**Enforcement.** The independent verifier already required by the stamping
precondition checks voice alongside claims: banned-list pass plus the
exemplar test. A voice miss is a finding like any other.

## Heavy reference: `references/brochure-design.md`

The visual standard for rendered brochures, adapted from
amplifier-bundle-stories `context/presentation-styles.md` and
`context/responsive-design.md` (MIT, microsoft/amplifier-bundle-stories
@ 3657bf1 — license and SHA verified against the clone; note provenance in
the file). **The guideline files are normative, not their example:** the
shipped `stories-bundle-overview.html` predates its own guidelines (fixed
pixel sizes, zero `clamp()`) — we copy the artifact *class* (single-file
keynote-dark HTML deck) and follow the guidelines, not the example's CSS.
Contents:

- One skeleton: deck (slides, nav dots, one small nav script, keyboard and
  touch navigation, `prefers-reduced-motion` respected). No page/one-pager
  mode — nothing upstream to adapt, and unproven breadth is YAGNI; add it
  later if a real reader needs it.
- Fluid typography via `clamp()`; never fixed pixel sizes for type or
  icons.
- WCAG AA contrast floors; the surface-hierarchy custom properties for dark
  cards; the forbidden-opacity rules.
- Self-containment constraints: one file, inline CSS, system font stack, no
  external dependencies, no build step. Size is advisory: stay lean (the
  reference deck is ~29 KB; the dry-run decks land ~17 KB); never inline
  fonts or images.
- Style default: the info-dense dark style; restraint rules (show the demo,
  not the adjectives). The render reads the resolved voice's **Look** knobs
  (accent color, density) and writes copy in the resolved voice — the
  visual register is part of voice, not a constant. An in-deck accent shift
  for the owner act (warm accent on Act III) proved effective in the dry
  run for signposting the register change; the design standard documents it
  as the default act treatment.
- Per-slide citation footers (the muted "docs/X.md §Y" line) — the deck's
  distinctive honesty move; every slide cites the doc that verifies it.

## Reference: `references/voice.md`

The voice-spec format, the four presets in full (with their extra rules),
the default slop-tell list, the exemplar-test procedure, and the founder
interview requirement.

## Template: `templates/BROCHURE-template.md`

Instantiable skeleton matching the BROCHURE.md sections above (cast-mirrored:
what you get / using it / running it / fit by role / limitations by bearer /
two getting-started paths), with the re-render pointer comment (regeneration
rule above) and an HTML comment reminding that each capability bullet
carries a citation. **No stamp sentinel:** a bare sentinel makes
`docmaint stamp --set` raise (sentinel present, line unparseable); the first
stamp appends the full block itself — matching v1's DICTIONARY-template,
which ships no sentinel either. (`templates/`, not `artifacts/` — dotfiles
gitignores `artifacts/`.)

## Skill file layout

```
writing-documentation/
  SKILL.md                      # hub: law + dispatch + red flags/rationalizations
  references/doc-portfolio.md   # readers × moments model, mis-address test (Diátaxis-grounded)
  references/user-docs.md       # set design + per-doc craft
  references/marketing.md       # cast law + story law + BROCHURE.md flow + brochure rendering
  references/voice.md           # voice-spec format, four presets, slop tells, exemplar test
  references/brochure-design.md # heavy reference (adapted, MIT-attributed)
  templates/BROCHURE-template.md
```

Like v1, the hub knowingly exceeds writing-skills' <500-word target: it is a
hub-law skill, and the budget discipline is honored structurally — law lives
once in the hub, process in flow files, heavy reference split out.

## Pragmatism and non-goals

- Per-project outputs (BROCHURE.md, brochure.html, user docs) are ordinary
  docs. v1's two-artifact law holds: dictionary and index remain the only
  metadata files — voice rides *inside* the dictionary precisely to avoid a
  third. **Zero docmaint changes.**
- No generator script: the agent renders the brochure; the design standard
  is prose, not tooling.
- No additional output formats (PPTX, PDF, social threads, newsletters) —
  amplifier's breadth is explicitly rejected as YAGNI.
- No light-mode palette yet; the Look knob ships with accent and density
  only.
- Out of scope: superpowers migration; the deferred
  maintaining-documentation entry points ("document this term", "validate
  and revise"); changes to maintaining-documentation itself.

## Testing and eval

Writing-skills Iron Law applies: no skill (or edit) without a failing test
first.

**RED — baselines without the skill,** session-driver workers, findings
captured verbatim as the seed of the rationalization table:

1. "Create an HTML brochure for superpowers-cloud-server." Expected
   failures: fabricated demo output, uncashed capability claims, outcome
   claims with no measurement, voice-from-nowhere hype, user/owner roles
   blended.
2. "Write a getting-started guide for superpowers-cloud-server." Expected
   failures: imagined command output, no named reader, prerequisites
   missing, internal references, the contributor sandbox passed off as the
   user path.

**GREEN — same scenarios with the skill,** plus application-scenario tests
(technique-skill type per writing-skills): the cast/voice confirm gate
fires; claims carry citations; the brochure carries the generated-file
sentinel; limitations land with the reader who bears them; voice passes the
banned list and exemplar test. The routing probe lives here, not in RED:
"document this module's internals" must route OUT to
maintaining-documentation — a non-capture assertion that only means
something with the skill present (without it there is no wrong behavior to
observe).

**Live eval (gating):** worker on superpowers-cloud-server produces
BROCHURE.md + brochure.html + one user doc (getting-started), evaluated
against the law. The superpowers repo is a **follow-up, not acceptance**:
it first needs its own maintaining-documentation bootstrap (a human-gated
pass on another repo — not something this skill's GREEN may depend on).

**Validation already in hand (2026-06-09 dry runs, by the design session
itself):** the three-act/cast structure, the claims-from-stamped-docs
sourcing pattern, the citation footers, and all four voice presets were
exercised end-to-end against superpowers-cloud-server —
`/tmp/cloud-build-brochure-dryrun/` holds ABOUT.md (written before the
BROCHURE.md rename) plus five rendered
decks (v3 default + four voice variants under `voices/`), each verified
rendering in Chrome. These are design evidence, not test fixtures; the RED
baselines above still run clean at implementation time.

**Seed red flags** (grown from baseline findings): writing before naming
reader/moment/job; outcome claim without measurement; example output never
run; hand-editing brochure.html; "it's just marketing"; pointing users at
internal docs; writing into a project with no confirmed index; pitching
operator plumbing to the user mid-seduction (or selling the owner's burden
as a user benefit); a "get started" that is secretly the contributor path
("clone the repo and `go run`" is not how a user starts on a deployed
product); an enacting surface attributed to a reader who never performs
it; a pitch that opens on the promise with no named, cashable problem; "I know this is true from context" — if the repo doesn't cash it,
it doesn't ship; every headline is an imperative fragment or a triad
(voice-from-nowhere — resolve and apply the project voice); reaching for a
metaphor before stating the literal fact; first-person color in the founder
voice that no interview produced.
