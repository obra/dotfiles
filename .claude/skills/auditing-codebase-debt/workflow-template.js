// Workflow script template for a deep debt audit. Pass it inline to the Workflow tool.
// Fill every <PLACEHOLDER>. Load the workflow-authoring skill first. Plain JS only.
export const meta = {
  name: '<repo>-debt-audit',
  description: 'Deep tech-debt, slop and duplication audit with verified findings and a fix roadmap',
  phases: [
    { title: 'Audit', detail: 'one deep finder per scoped slice, writes raw report' },
    { title: 'Verify', detail: 'adversarial verifier per slice re-checks every finding' },
    { title: 'Synthesize', detail: 'cross-slice themes, dedup, root causes' },
    { title: 'Roadmap', detail: 'PR-sized fix sequence + completeness critic' },
  ],
}

const ROOT = '<ABSOLUTE WORKTREE PATH>'
const OUT = ROOT + '/<docs/audits/YYYY-MM-DD-tech-debt>'
const M = undefined // or e.g. 'sonnet' if the user prefers a model for subagents

// Scope strings must be precise enough that two slices never claim the same file.
const SLICES = [
  // ---- per-area production slices (5-20k lines each; split god packages by file prefix) ----
  { slug: '<area-a>', scope: '<path globs, non-test, approx size>' },
  // ---- test-code slices ----
  { slug: 'tests-<area>', scope: '<test file globs>. Duplicated helpers/fixtures, tests of mocks, assertions on copy, coverage-chasing files, sleeps.' },
  // ---- build / gates ----
  { slug: 'build-gates-scripts', scope: 'Makefile, CI workflows, scripts/, meta/audit tests, budgets. Has meta-testing sprawled or duplicated lint?' },
  // ---- cross-cutting sweeps (keep all; delete only if the repo truly lacks the surface) ----
  { slug: 'x-client-duplication', scope: 'CROSS-CUTTING: logic re-implemented across client apps instead of imported from the shared library.' },
  { slug: 'x-protocol-mirrors', scope: 'CROSS-CUTTING: hand-maintained mirrors across languages/layers (types, enums, constants, error codes), codegen gaps.' },
  { slug: 'x-duplicate-functions', scope: 'CROSS-CUTTING: catalog small helpers by purpose (atomic write, path, retry, truncate, clone, env, time); report clusters with 2+ implementations and pick the canonical one.' },
  { slug: 'x-dead-code', scope: 'CROSS-CUTTING: dead code. Cheap static tools allowed (deadcode, unused linters, zero-importer exports). No test suites.' },
  { slug: 'x-compat-legacy', scope: 'CROSS-CUTTING: compat shims, migrations, fallbacks, deprecated aliases, TODO/FIXME inventory with age.' },
  { slug: 'x-docs', scope: 'CROSS-CUTTING DOCS: evergreen-doc drift vs code, broken links, stale plans/specs, duplicated docs, agent-instruction bloat.' },
  { slug: 'x-slop-patterns', scope: 'CROSS-CUTTING: swallowed errors, impossible nil checks, single-impl interfaces, pass-through wrappers, narration comments, giant functions/files, mutable func-var test seams. Quantify with grep counts.' },
  { slug: 'x-seams-artifacts', scope: 'CROSS-CUTTING: test-seam libraries in production signatures (e.g. in-memory FS); committed fuzz corpora, generated bundles, files over 1MB; third-language test suites no gate runs.' },
  { slug: 'x-runtime-hygiene', scope: 'CROSS-CUTTING: logging consistency (ad hoc prefixes, private loggers), goroutine/context lifetime (context.Background in request paths), toolchain/dependency version skew across package trees.' },
]

const FINDINGS = {
  type: 'object',
  properties: {
    slug: { type: 'string' },
    summary: { type: 'string', description: '3-6 sentence health assessment of the slice' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string', description: 'slug-N' },
          title: { type: 'string' },
          category: { type: 'string', enum: ['duplication', 'dead-code', 'slop', 'complexity', 'test-debt', 'doc-drift', 'compat-legacy', 'inconsistency', 'architecture', 'other'] },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          locations: { type: 'array', items: { type: 'string' }, description: 'file:line references you actually read' },
          evidence: { type: 'string' },
          impact: { type: 'string' },
          fix_plan: { type: 'string', description: 'canonical home, what to delete/extract, test strategy, docs' },
          fix_size_loc: { type: 'string' },
          risk: { type: 'string' },
          cross_cutting: { type: 'boolean' },
        },
        required: ['id', 'title', 'category', 'severity', 'locations', 'evidence', 'fix_plan'],
      },
    },
  },
  required: ['slug', 'summary', 'findings'],
}

const VERDICTS = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string', enum: ['confirmed', 'partial', 'refuted'] },
          severity: { type: 'string', enum: ['high', 'medium', 'low'] },
          note: { type: 'string' },
          revised_fix_plan: { type: 'string' },
        },
        required: ['id', 'verdict', 'severity', 'note'],
      },
    },
  },
  required: ['verdicts'],
}

const RULES = `
Ground rules (hard):
- Repo worktree: ${ROOT}. READ-ONLY for source: write only the single report file you are told to write. Never checkout/stash/commit.
- Do NOT run test suites or race/stress loops. grep, wc, git log/blame, single-package vet and cheap static analysis are fine.
- Every finding cites file:line locations you opened and concrete evidence (quotes, counts, sizes). No speculation.
- Context: <ONE PARAGRAPH: what the repo is, its main components, which shared library owns shared logic>.
- Read <AGENTS.md / CLAUDE.md / product docs> first so fix plans respect the ownership model.
- Fix plans: simplest thing that works, delete before adding, consolidate into one canonical home, no new backward-compat without approval, behavior tests before behavior changes, update evergreen docs in the same change. Sizes in lines, never time.
- Severity: high = causes bugs/drift or large drag; medium = worth a PR; low = cosmetic.
- Go deep: read the code, aim for 10-30 findings for a large slice.`

const auditPrompt = s => `You are a senior engineer doing a deep technical-debt, slop and duplication audit of ONE slice.

SLICE: ${s.slug}
SCOPE: ${s.scope}
${RULES}

Inventory the slice, read the largest and most central files carefully, hunt duplication within the slice and against the rest of the repo, and design a fix for each problem.
Write a markdown report to ${OUT}/raw/${s.slug}.md (inventory, each finding, then "Recommended fix sequence"). Return the same findings as structured output with ids "${s.slug}-N".`

const verifyPrompt = (s, r) => `You are an adversarial verifier. Another engineer audited slice "${s.slug}" (scope: ${s.scope}); raw report at ${OUT}/raw/${s.slug}.md.
${RULES}

For EVERY finding: open the cited code and try to REFUTE it. Check that "duplicates" are actually semantically the same, that "dead" code has no callers anywhere (other languages, tests, build tags, scripts, registration by name), that the fix is safe for the product's guarantees, and that the severity is right. Default to "refuted" if you cannot confirm. Use "partial" when the core holds but details/severity/fix are off, and give revised_fix_plan.
Write the original findings merged with your verdict fields as JSON to ${OUT}/verified/${s.slug}.json.

FINDINGS:
${JSON.stringify(r.findings, null, 1)}`

phase('Audit')
const results = await pipeline(
  SLICES,
  s => agent(auditPrompt(s), { label: `audit:${s.slug}`, phase: 'Audit', schema: FINDINGS, model: M }),
  (r, s) => {
    if (!r || !r.findings || !r.findings.length) return { slug: s.slug, summary: r ? r.summary : 'AUDIT FAILED', findings: [], verdicts: [] }
    return agent(verifyPrompt(s, r), { label: `verify:${s.slug}`, phase: 'Verify', schema: VERDICTS, model: M })
      .then(v => ({ slug: s.slug, summary: r.summary, findings: r.findings, verdicts: v ? v.verdicts : [] }))
  },
)

const ok = results.filter(Boolean)
const failed = SLICES.map(s => s.slug).filter(sl => !ok.find(r => r.slug === sl && r.findings.length))
if (failed.length) log(`Slices with no findings or failed audits: ${failed.join(', ')}`)

// Compact index only: the synthesis agent reads details from the files.
const tally = { confirmed: 0, partial: 0, refuted: 0, unverified: 0 }
const compact = ok.map(r => {
  const byId = Object.fromEntries((r.verdicts || []).map(v => [v.id, v]))
  return {
    slug: r.slug,
    summary: r.summary,
    findings: r.findings.map(f => {
      const v = byId[f.id]
      tally[v ? v.verdict : 'unverified']++
      return { id: f.id, title: f.title, category: f.category, severity: v ? v.severity : f.severity, verdict: v ? v.verdict : 'unverified' }
    }),
  }
})
log(`Findings: ${JSON.stringify(tally)}`)

phase('Synthesize')
const synth = await agent(`You are the lead engineer synthesizing a debt audit of ${ROOT}.
${RULES}
Inputs: ${OUT}/raw/*.md and ${OUT}/verified/*.json. Ignore refuted findings; prefer revised_fix_plan. Index:
${JSON.stringify(compact)}
Write ${OUT}/SYNTHESIS.md: (1) executive summary with the 5-8 biggest themes and rough LOC size; (2) defects to fix first; (3) cross-cutting themes, each with root cause, member ids, canonical fix, and a guardrail that reuses existing tooling; (4) per-area scorecard (health 1-5, H/M/L counts, top issue); (5) conflicts between slices, reconciled; (6) things that look like debt but should stay. Spot-check claims your themes hinge on. Return a 15-line summary.`, { label: 'synthesize', phase: 'Synthesize', model: M })

phase('Roadmap')
const roadmap = await agent(`Plan the cleanup of ${ROOT} from the audit.
${RULES}
Read ${OUT}/SYNTHESIS.md, ${OUT}/verified/*.json, and ${OUT}/raw/*.md as needed. Write ${OUT}/ROADMAP.md: PR-sized items (aim under ~800 changed lines each). Each has title, finding ids, files, steps, test strategy, docs, net LOC, risk, gate (a named decision or "none"), and dependencies. Include a lanes table: PRs touching the same files share a lane and merge in order. Waves: 0 = guardrails, small defects (red test first), deletions of verified-dead code; 1 = consolidations; 2 = structural splits, each marked "needs design discussion". End with the human's decisions as named questions, each listing what it unblocks. Return a summary.`, { label: 'roadmap', phase: 'Roadmap', model: M })

const critic = await agent(`You are a completeness critic for a debt audit of ${ROOT}.
${RULES}
Slices: ${SLICES.map(s => s.slug + ' = ' + s.scope).join('\n')}
Failed/empty slices: ${failed.join(', ') || 'none'}.
Read ${OUT}/SYNTHESIS.md and ${OUT}/ROADMAP.md. (1) List directories with meaningful code that no slice covered, or covered thinly. (2) Spot-check 3-5 of those gaps and record real debt with file:line evidence. (3) Flag roadmap items that look unsafe, oversized, mis-ordered, or that miss registry files they must edit. (4) Name debt categories missed entirely. Write ${OUT}/GAPS.md and return a short summary.`, { label: 'critic', phase: 'Roadmap', model: M })

return { tally, failed, synth, roadmap, critic }
