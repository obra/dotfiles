---
name: Writing Evergreen Comments
description: Write comments explaining WHAT and WHY, never temporal context or history
when_to_use: When adding comments to code. When documenting during refactoring. When tempted to explain "what changed". When writing file headers. When reviewing comments that reference history.
version: 1.0.0
languages: all
type: technique
---

# Writing Evergreen Comments

## Overview

Comments documenting change history or implementation improvements become stale and confusing. "// Refactored from legacy system" tells nothing about current purpose.

**Core principle:** Comments explain WHAT code does or WHY it exists, never how it's better than before.

**Violating the letter of this rule is violating the spirit of documentation.**

## When to Use

**Use for:**
- File headers (ABOUTME pattern)
- Function/class documentation
- Complex logic explanation
- Non-obvious WHY reasoning

**Use ESPECIALLY when:**
- Refactoring code (tempted to document the change)
- Replacing implementations (tempted to explain old vs new)
- Improving code (tempted to say "better" or "enhanced")
- Reviewing old comments (tempted to preserve history)

## The Rules

### NEVER Document Changes or History

Comments describe present state, not past or transitions.

<Bad>
```typescript
// Refactored from the old validation system
// Now uses Zod instead of manual checking
class Validator {
  validate(data: unknown) { }
}

// Improved error handling - used to just throw
function processRequest() { }

// Recently moved from utils/ to core/
export function helper() { }
```
</Bad>

<Good>
```typescript
// Validates configuration against schema
class Validator {
  validate(data: unknown) { }
}

// Returns error details to caller for proper handling
function processRequest() { }

// Shared utility for data transformation
export function helper() { }
```
</Good>

### NEVER Add Instructional Comments

Comments document code, not instruct developers.

<Bad>
```typescript
// Use this pattern instead of the old approach
// Copy this when implementing similar features
class NewPattern { }

// TODO: migrate all code to use this
function improvedAPI() { }
```
</Bad>

<Good>
```typescript
// Handles async operations with automatic retry
class RetryableOperation { }

// Validates input before processing
function processInput() { }
```
</Good>

### NEVER Explain "Better" or "Improved"

Code quality shows in behavior, not comments claiming superiority.

<Bad>
```typescript
// Better than the previous implementation
// More efficient validation
// Enhanced error messages
class Validator { }
```
</Bad>

<Good>
```typescript
// Validates schema in single pass, returns all errors
class Validator { }
```
</Good>

### ALWAYS Use ABOUTME for File Headers

Every file starts with 2-line header explaining purpose.

<Good>
```typescript
// ABOUTME: Validates user input against defined schemas
// ABOUTME: Provides detailed error messages for debugging

export class Validator {
  // ...
}
```
</Good>

**Why ABOUTME:** Greppable pattern for finding file purposes.

```bash
grep -r "ABOUTME:" . --include="*.ts"
```

## Quick Reference

| Bad Comment | Why Bad | Good Comment |
|-------------|---------|--------------|
| `// Refactored from legacy` | Temporal context | `// Handles user authentication` |
| `// New error handling` | References change | `// Returns errors to caller` |
| `// Improved performance` | Claims improvement | `// Caches results for 5min` |
| `// Use this instead of X` | Instructional | `// Validates async` |
| `// Wrapper around API` | Implementation | `// Fetches user data` |
| `// Recently moved here` | Temporal context | `// Shared validation logic` |

## When Refactoring

**Rule:** Remove old comments describing old behavior. Don't add new comments about the change.

<Bad>
```typescript
// OLD: Used to validate with regex
// NEW: Now uses schema validation for better accuracy
function validate(input: string) {
  // Enhanced validation logic
}
```
</Bad>

<Good>
```typescript
// Validates input against schema, returns structured errors
function validate(input: string) {
  // Business logic here
}
```
</Good>

## Preserving Existing Comments

**Critical:** Never remove comments unless proven false.

```typescript
// DO remove if provably wrong
// OLD COMMENT: Returns null on error
function process() {
  throw new Error(); // ← Comment was false, remove it
}

// PRESERVE if still accurate
// Retries up to 3 times before failing
function fetch() {
  // Even if you refactor, keep comment if behavior same
}
```

## Red Flags - STOP and Rewrite

If you catch yourself writing:
- "Refactored", "Improved", "Better", "Enhanced", "New"
- "Old", "Legacy", "Previously", "Used to"
- "Recently", "Now", "Updated", "Modern"
- "Use this instead", "Copy this pattern", "Migrate to"
- "Was", "Changed from", "Moved from", "Unified"

**STOP. Write comment describing current behavior and purpose.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Developers need to know what changed" | Git history records changes. Comments describe current state. |
| "This explains why refactoring was done" | Explain WHY current code exists, not what it replaced. |
| "Future devs should use this pattern" | Code quality speaks for itself. Don't instruct. |
| "The old comment has useful context" | If false, delete. If true, rewrite in present tense. |
| "Need to mark this as 'new' temporarily" | If it's running, it's not temporary. Describe what it IS. |

## The ABOUTME Pattern

**Every file starts with 2-line header:**

```typescript
// ABOUTME: First line - what this file does
// ABOUTME: Second line - key details or context

// Rest of file...
```

**Guidelines:**
- Exactly 2 lines
- Each starts with `ABOUTME: `
- Greppable and scannable
- Describes file purpose

<Good>
```typescript
// ABOUTME: Validates API requests against schemas
// ABOUTME: Returns structured errors with field-level details
```
</Good>

<Bad>
```typescript
// This file handles validation
// It was refactored from the old system
```
</Bad>

## Verification

Before committing comments:
- [ ] Explains WHAT or WHY (not "what changed")
- [ ] No temporal context
- [ ] No references to old implementations
- [ ] No instructional language
- [ ] File has ABOUTME header (2 lines)
- [ ] Existing accurate comments preserved
- [ ] No "new", "old", "improved", "refactored"

## Real-World Examples

### Bad Comments (Don't Do This)

```typescript
// ABOUTME: New validation system
// ABOUTME: Refactored from old regex approach

// This replaces the old validator - use this instead
// Better error handling than before
class Validator {
  // Enhanced validation logic (improved from v1)
  validate(data: unknown) { }
}
```

### Good Comments

```typescript
// ABOUTME: Validates configuration against schemas
// ABOUTME: Returns all errors in single pass

// Validates data structure and types
// Returns structured errors with field paths
class Validator {
  // Checks each field against schema rules
  validate(data: unknown) { }
}
```

## Integration with Naming

See @../naming-by-domain/SKILL.md for domain-focused naming (no temporal context in names either).
