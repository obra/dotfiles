---
name: Creating Skills
description: How to create effective skills for future Claude instances
when_to_use: When you discover a technique, pattern, or tool worth documenting for reuse. When you've written a skill and need to verify it works before deploying.
version: 3.0.0
languages: all
---

# Creating Skills

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in CLAUDE.md)

## Skill Types

### Technique
Concrete method with steps to follow (condition-based-waiting, root-cause-tracing)

### Pattern
Way of thinking about problems (flatten-with-flags, test-invariants)

### Reference
API docs, syntax guides, tool documentation (office docs)

All use same structure - type in frontmatter for context, not organization.

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

**Flat namespace** - all skills in one searchable location

**Separate files for:**
1. **Heavy reference** (100+ lines) - API docs, comprehensive syntax
2. **Reusable tools** - Scripts, utilities, templates

**Keep inline:**
- Principles and concepts
- Code patterns (< 50 lines)
- Everything else

## SKILL.md Structure

```markdown
---
name: Human-Readable Name
description: One-line summary of what this does
when_to_use: Symptoms and situations when you need this (CSO-critical)
version: 1.0.0
languages: all | [typescript, python] | etc
type: technique | pattern | reference
dependencies: (optional) Required tools/libraries
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
[Small inline flowchart IF decision non-obvious]

Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns
@link to file for heavy reference or reusable tools

## Common Mistakes
What goes wrong + fixes

## Real-World Impact (optional)
Concrete results
```

## Claude Search Optimization (CSO)

**Critical for discovery:** Future Claude needs to FIND your skill

### 1. Rich when_to_use

Include SYMPTOMS not just abstract use cases:

```yaml
# ❌ BAD: Too abstract
when_to_use: For async testing

# ✅ GOOD: Symptoms and context
when_to_use: When tests use setTimeout/sleep and are flaky, timing-dependent,
  pass locally but fail in CI, or timeout when run in parallel
```

### 2. Keyword Coverage

Use words Claude would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### 3. Descriptive Naming

**Use active voice, verb-first:**
- ✅ `creating-skills` not `skill-creation`
- ✅ `testing-skills-with-subagents` not `subagent-skill-testing`
- ✅ `using-skills` not `skill-usage`

**Name by what you DO or core insight:**
- ✅ `condition-based-waiting` > `async-test-helpers`
- ✅ `flatten-with-flags` > `data-structure-refactoring`
- ✅ `root-cause-tracing` > `debugging-techniques`

**Gerunds (-ing) work well for processes:**
- `creating-skills`, `testing-skills`, `debugging-with-logs`
- Active, describes the action you're taking

### 4. Content Repetition

Mention key concepts multiple times:
- In description
- In when_to_use
- In overview
- In section headers

Grep hits from multiple places = easier discovery

## Flowchart Usage

```dot
digraph when_flowchart {
    "Need to show information?" [shape=diamond];
    "Decision where I might go wrong?" [shape=diamond];
    "Use markdown" [shape=box];
    "Small inline flowchart" [shape=box];

    "Need to show information?" -> "Decision where I might go wrong?" [label="yes"];
    "Decision where I might go wrong?" -> "Small inline flowchart" [label="yes"];
    "Decision where I might go wrong?" -> "Use markdown" [label="no"];
}
```

**Use flowcharts ONLY for:**
- Non-obvious decision points
- Process loops where you might stop too early
- "When to use A vs B" decisions

**Never use flowcharts for:**
- Reference material → Tables, lists
- Code examples → Markdown blocks
- Linear instructions → Numbered lists
- Labels without semantic meaning (step1, helper2)

See @graphviz-conventions.dot for graphviz style rules.

## Code Examples

**One excellent example beats many mediocre ones**

Choose most relevant language:
- Testing techniques → TypeScript/JavaScript
- System debugging → Shell/Python
- Data processing → Python

**Good example:**
- Complete and runnable
- Well-commented explaining WHY
- From real scenario
- Shows pattern clearly
- Ready to adapt (not generic template)

**Don't:**
- Implement in 5+ languages
- Create fill-in-the-blank templates
- Write contrived examples

You're good at porting - one great example is enough.

## File Organization

### Self-Contained Skill
```
defense-in-depth/
  SKILL.md    # Everything inline
```
When: All content fits, no heavy reference needed

### Skill with Reusable Tool
```
condition-based-waiting/
  SKILL.md    # Overview + patterns
  example.ts  # Working helpers to adapt
```
When: Tool is reusable code, not just narrative

### Skill with Heavy Reference
```
pptx/
  SKILL.md       # Overview + workflows
  pptxgenjs.md   # 600 lines API reference
  ooxml.md       # 500 lines XML structure
  scripts/       # Executable tools
```
When: Reference material too large for inline

## The Testing Law

```
ALL SKILLS MUST BE TESTED WITH SUBAGENTS BEFORE DEPLOYMENT
```

**No exceptions:**
- Don't skip because "it's just a reference"
- Don't skip because "it's obviously clear"
- Don't skip because testing is tedious
- Don't skip because you're confident
- Don't skip because you're in a hurry
- Testing means testing. Run scenarios with subagents.

Untested skills have issues. Always. Testing reveals:
- Unclear instructions
- Missing steps
- Confusing wording
- Gaps in coverage
- Loopholes to close
- Better ways to explain things

**15 minutes testing > hours debugging bad skill usage.**

## Testing All Skill Types

Different skill types need different test approaches:

### Discipline-Enforcing Skills (rules/requirements)

**Examples:** TDD, verification-before-completion, designing-before-coding

**Test with:**
- Academic questions: Do they understand the rules?
- Pressure scenarios: Do they comply under stress?
- Multiple pressures combined: time + sunk cost + exhaustion
- Identify rationalizations and add explicit counters

**Success criteria:** Agent follows rule under maximum pressure

### Technique Skills (how-to guides)

**Examples:** condition-based-waiting, root-cause-tracing, defensive-programming

**Test with:**
- Application scenarios: Can they apply the technique correctly?
- Variation scenarios: Do they handle edge cases?
- Missing information tests: Do instructions have gaps?

**Success criteria:** Agent successfully applies technique to new scenario

### Pattern Skills (mental models)

**Examples:** reducing-complexity, information-hiding concepts

**Test with:**
- Recognition scenarios: Do they recognize when pattern applies?
- Application scenarios: Can they use the mental model?
- Counter-examples: Do they know when NOT to apply?

**Success criteria:** Agent correctly identifies when/how to apply pattern

### Reference Skills (documentation/APIs)

**Examples:** API documentation, command references, library guides

**Test with:**
- Retrieval scenarios: Can they find the right information?
- Application scenarios: Can they use what they found correctly?
- Gap testing: Are common use cases covered?

**Success criteria:** Agent finds and correctly applies reference information

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

**All of these mean: Test before deploying. No exceptions.**

## Bulletproofing Skills Against Rationalization

Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes when under pressure.

### Close Every Loophole Explicitly

Don't just state the rule - forbid specific workarounds:

<Bad>
```markdown
Write code before test? Delete it.
```
</Bad>

<Good>
```markdown
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```
</Good>

### Address "Spirit vs Letter" Arguments

Add foundational principle early:

```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

This cuts off entire class of "I'm following the spirit" rationalizations.

### Build Rationalization Table

Capture rationalizations from baseline testing (see Testing section below). Every excuse agents make goes in the table:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
```

### Create Red Flags List

Make it easy for agents to self-check when rationalizing:

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**
```

### Update CSO for Violation Symptoms

Add to when_to_use: symptoms of when you're ABOUT to violate the rule:

```yaml
when_to_use: Every feature and bugfix. When you wrote code before tests.
  When you're tempted to test after. When manually testing seems faster.
```

## Testing Skills With Subagents

**Don't trust untested skills.** Use subagents to stress-test before deploying.

See @../testing-skills-with-subagents/SKILL.md for complete methodology.

### The Baseline Testing Principle

**CRITICAL: Test pressure scenarios BEFORE writing the skill.**

This establishes baseline behavior - what do agents naturally do under pressure WITHOUT the skill? This reveals:
- What rationalizations occur naturally
- Which pressures are most effective
- What the skill must prevent
- Exact wording agents use to justify violations

**Then write skill specifically countering those baseline rationalizations.**

This is far more efficient than write→test→iterate.

### Testing Process

**For discipline-enforcing skills:**

- [ ] **Create pressure scenarios first** (time pressure, sunk cost, authority, exhaustion)
- [ ] **Run baseline tests WITHOUT skill** - what do agents naturally do?
- [ ] **Document exact rationalizations** they use verbatim
- [ ] **Write skill addressing those specific rationalizations** with explicit counters
- [ ] **Test WITH skill** - do they now comply?
- [ ] **Identify any NEW rationalizations** and add counters
- [ ] **Re-test until bulletproof**

**For other skill types:**

- [ ] **Create application scenarios**
- [ ] **Test WITHOUT skill** - can they figure it out? (baseline difficulty)
- [ ] **Write skill** based on what was confusing
- [ ] **Test WITH skill** - does it help?
- [ ] **Iterate** based on gaps

**Key insight:** Baseline testing (before skill) reveals what needs to be prevented. Writing first reveals what you THINK needs to be prevented. Agents are creative - test reality first.

## Anti-Patterns

### ❌ Narrative Example
"In session 2025-10-03, we found empty projectDir caused..."
**Why bad:** Too specific, not reusable

### ❌ Multi-Language Dilution
example-js.js, example-py.py, example-go.go
**Why bad:** Mediocre quality, maintenance burden

### ❌ Code in Flowcharts
```dot
step1 [label="import fs"];
step2 [label="read file"];
```
**Why bad:** Can't copy-paste, hard to read

### ❌ Generic Labels
helper1, helper2, step3, pattern4
**Why bad:** Labels should have semantic meaning

## STOP: Before Moving to Next Skill

**After writing ANY skill, you MUST STOP and complete the deployment process.**

**Do NOT:**
- Create multiple skills in batch without testing each
- Update INDEX.md before testing skills
- Move to next skill before current one is verified
- Skip testing because "batching is more efficient"

**The deployment checklist below is MANDATORY for EACH skill.**

Deploying untested skills = deploying untested code. It's a violation of quality standards.

## Skill Creation Checklist

**IMPORTANT: Use TodoWrite to create todos for EACH checklist item below.**

This ensures you complete all steps systematically and don't skip any.

**Before writing:**
- [ ] Technique applies broadly (not project-specific)
- [ ] Non-obvious enough to document
- [ ] Would reference this again

**While writing:**
- [ ] Name describes what you DO or core insight
- [ ] YAML frontmatter with rich when_to_use (include symptoms!)
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Type marked (technique/pattern/reference)
- [ ] Clear overview with core principle
- [ ] Small flowchart only if decision non-obvious
- [ ] Quick reference table
- [ ] Code inline OR @link to separate file
- [ ] Common mistakes section
- [ ] One excellent example (not multi-language)
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**After writing (BEFORE deploying):**
- [ ] Test with subagents (see @../testing-skills-with-subagents/SKILL.md)
- [ ] Use appropriate test type for skill type (see Testing All Skill Types above)
- [ ] Iterate based on subagent feedback until skill is clear and usable
- [ ] Address all confusion, gaps, or unclear sections found during testing

**Additionally, if skill enforces discipline:**
- [ ] Add foundational principle ("Violating letter is violating spirit")
- [ ] Close loopholes explicitly (no "reference", no "adapt")
- [ ] Build rationalization table from test results
- [ ] Create red flags list
- [ ] Update when_to_use with violation symptoms
- [ ] Use pressure scenarios (not just academic questions) in testing
- [ ] Iterate until bulletproof against rationalization

## Discovery Workflow

How future Claude finds your skill:

1. **Encounters problem** ("tests are flaky")
2. **Greps skills** (`grep -r "flaky" ~/.claude/skills/`)
3. **Finds SKILL.md** (rich when_to_use matches)
4. **Scans overview** (is this relevant?)
5. **Reads patterns** (quick reference table)
6. **Loads example** (only when implementing)

**Optimize for this flow** - put searchable terms early and often.
