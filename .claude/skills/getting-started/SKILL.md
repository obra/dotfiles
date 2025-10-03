---
name: Getting Started with Skills
description: Introduction to the skills library - what it is, how to use it, how to contribute
when_to_use: Read this once at start of each project or when you need a refresher
version: 1.0.0
type: reference
---

# Getting Started with Skills

## What is This?

Your personal wiki of proven techniques, patterns, and tools at `~/.claude/skills/`. External memory for effective approaches from past sessions.

## Skill Types

**Techniques:** Concrete methods (condition-based-waiting, root-cause-tracing)
**Patterns:** Ways of thinking (flatten-with-flags, test-invariants)
**References:** API docs, syntax guides (office docs)

## Navigation

**Start:** @../INDEX.md - Categories with descriptions

**Categories:**
- @../testing/INDEX.md
- @../debugging/INDEX.md
- @../architecture/INDEX.md
- @../collaboration/INDEX.md
- @../meta/INDEX.md

**Individual skills:** From category INDEX, load: `@../testing/condition-based-waiting/SKILL.md`

**Supporting files:** Load only when needed (`example.ts`, `script.sh`)

## Using Skills

### Quick Evaluation (2 min)
1. Frontmatter: Does `when_to_use` match?
2. Overview: Core principle relevant?
3. Quick reference: Any patterns match?
4. Implementation: How to apply?
5. Supporting files: Load only when implementing

### Application
- **Techniques:** Follow pattern, adapt code
- **Patterns:** Understand model, evaluate fit, implement if beneficial
- **References:** Find task, follow workflow

Skills are starting points - adapt to your context.

## Searching

**By symptom:** `grep -r "keyword" ~/.claude/skills/ --include="SKILL.md"`
**By category:** Read category INDEX (@../testing/INDEX.md)
**Ask Jesse:** "Do I have a skill for X?"

## When to Check

- Starting new task
- Unfamiliar problem type
- Writing test infrastructure
- Debugging confusion
- Architectural decisions
- Multiple failures
- Stuck

30-second check beats reinventing.

## Creating Skills

Found something valuable?
1. Note it (don't interrupt work)
2. Create while fresh
3. Follow @../meta/skill-creation/SKILL.md

## Requesting Skills

Want a skill that doesn't exist? Edit @../REQUESTS.md with what you need, when you'd use it, and why it's non-obvious.

## Principles

- Check before implementing
- Adapt, don't force
- Load on-demand
- Contribute back
- CSO: Rich keywords aid discovery

## Quick Reference

| Need | Action |
|------|--------|
| Browse all | @../INDEX.md |
| Testing | @../testing/INDEX.md |
| Debugging | @../debugging/INDEX.md |
| Architecture | @../architecture/INDEX.md |
| Search | `grep -r "keyword" ~/.claude/skills/` |
| Create skill | @../meta/skill-creation/SKILL.md |
| Request skill | Edit @../REQUESTS.md |

Skills are tools that help, not mandates. Use when relevant.
