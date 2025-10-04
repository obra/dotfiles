# Coding Skills

Core software engineering practices for writing clean, maintainable code.

## Available Skills

### Design & Construction Process

- @designing-before-coding/SKILL.md - Design in pseudocode first, iterate approaches, then translate to code. Use before implementing any non-trivial routine. Use when jumping straight to code, in "just one more compile" cycle, or when code feels hack-y.

- @exploring-alternatives/SKILL.md - Try 2-3 different approaches before implementing - don't settle for first design. Use before implementing any non-trivial solution, when first idea feels complex, when choosing between approaches, when tempted to code first idea immediately.

### Naming

- @naming-by-domain/SKILL.md - Name code by what it does in the domain, not how it's implemented or its history. Use when naming anything, especially during refactoring when tempted to add "New" or "Improved".

- @naming-variables/SKILL.md - Choose names that fully and accurately describe what the variable represents. Use when naming variables, when seeing cryptic names, when struggling to name something (warning sign of design problem).

### Variables

- @localizing-variables/SKILL.md - Declare variables in smallest possible scope, initialize close to first use, minimize span and live time. Use when writing any code with variables, when variables are scattered or declared at top of function, when reviewing code with large variable scope.

- @single-purpose-variables/SKILL.md - Use each variable for exactly one purpose - no hybrid coupling or hidden meanings. Use when variable represents different things at different times, when -1 or special values indicate errors, when reusing temp for unrelated purposes, when variable meaning changes.

### Code Quality

- @validating-inputs/SKILL.md - Check all external inputs for validity - garbage in, nothing out. Use before implementing any function receiving external data, when writing functions taking parameters from users/APIs/databases, when you see missing validation or silent failures.

- @keeping-routines-focused/SKILL.md - Each routine does one thing and does it well - extract when routines have multiple responsibilities. Use when writing any function, when routine description has "and", when routine is hard to name, when longer than 200 lines, when parameter list exceeds 7.

- @refactoring-safely/SKILL.md - Refactor with tests first, one change at a time, never mix refactoring with bug fixes or features. Use before refactoring any code, when discovering bugs during refactoring, when tempted to "fix while I'm here", when making multiple changes at once, when refactoring without tests.

- @simplifying-control-flow/SKILL.md - Flatten nested conditionals with early returns or table-driven methods - keep nesting depth under 3 levels. Use when writing conditional logic, when nesting depth exceeds 2-3 levels, when multiple conditions determine outcome, when business rules encoded in nested ifs.

### Documentation

- @commenting-intent/SKILL.md - Comment WHY code exists and non-obvious decisions, not WHAT code does (mechanics). Use when adding comments, when code review requests more comments, when over-commenting obvious code, when magic numbers exist, when non-obvious decisions made.

- @writing-evergreen-comments/SKILL.md - Write comments explaining WHAT and WHY, never temporal context or history. Use when documenting code, especially during refactoring when tempted to explain "what changed".

## Core Principles

These skills implement Code Complete's software construction fundamentals:

**1. Design Before Implementation**
- Design in pseudocode first (designing-before-coding)
- Explore 2-3 alternatives (exploring-alternatives)
- Pick best approach, THEN code

**2. Managing Complexity**
- Keep routines focused on single responsibility (keeping-routines-focused)
- Minimize variable scope and live time (localizing-variables)
- Break into simple pieces

**3. Defensive Quality**
- Validate all external inputs (validating-inputs)
- Name things clearly and accurately (naming-variables, naming-by-domain)
- Document with evergreen comments (writing-evergreen-comments)

**4. Code in the Present**
- Names describe domain purpose (not implementation or history)
- Comments explain current behavior (not what changed)
- No temporal context ("new", "old", "refactored", "improved")

**Together:** These create self-documenting, maintainable code built through disciplined construction process.
