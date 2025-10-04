---
name: Domain-Focused Naming
description: Name code by what it does in the domain, not how it's implemented or its history
when_to_use: When naming variables, functions, classes, modules. When reviewing code with vague names. When refactoring and tempted to add "New" or "Improved". When using implementation details like "ZodValidator" or pattern names like "Factory".
version: 1.0.0
languages: all
type: technique
---

# Domain-Focused Naming

## Overview

Names documenting implementation or history create confusion. "NewUserAPI" doesn't tell what it does. "ZodValidator" exposes internals.

**Core principle:** Names tell what code does in the domain, not how it's built or what it replaced.

**Violating the letter of this rule is violating the spirit of naming.**

## When to Use

**Use for:**
- Variables, functions, classes, modules
- Refactoring existing code
- Code review feedback
- API design

**Use ESPECIALLY when:**
- Refactoring (tempted to add "New" or "Improved")
- Replacing implementations (tempted to add "Zod" or "MCP")
- Using design patterns (tempted to add "Factory" or "Manager")
- Documenting changes (tempted to add "Unified" or "Enhanced")

## The Rules

### NEVER Use Implementation Details

Names expose WHAT, not HOW.

<Bad>
```typescript
class ZodValidator { }          // Exposes Zod library
class MCPToolWrapper { }        // Exposes MCP protocol
class JSONConfigParser { }      // Exposes JSON format
```
</Bad>

<Good>
```typescript
class Validator { }             // What it does
class RemoteTool { }           // What it represents
class ConfigReader { }         // What it does
```
</Good>

### NEVER Use Temporal Context

Code exists in present. Don't reference past or transitions.

<Bad>
```typescript
class NewAPI { }               // When does it stop being "new"?
class LegacyHandler { }        // Calls it legacy but it's running
class ImprovedParser { }       // Improved from what?
class UnifiedService { }       // What was unified?
class EnhancedValidator { }    // Enhanced how?
```
</Bad>

<Good>
```typescript
class API { }                  // What it is now
class Handler { }              // What it does now
class Parser { }               // What it does now
class Service { }              // What it is now
class Validator { }            // What it does now
```
</Good>

### NEVER Use Pattern Names (Unless They Add Clarity)

Patterns are implementation details. Most don't help understanding.

<Bad>
```typescript
class ToolFactory { }          // "Factory" adds nothing
class ServiceBuilder { }       // "Builder" adds nothing
class ManagerSingleton { }     // "Singleton" adds nothing
```
</Bad>

<Good>
```typescript
class Tool { }                 // Clear without pattern
class Service { }              // Clear without pattern
class Registry { }             // Clear without pattern

// OK when pattern IS the purpose
class EventEmitter { }         // Observer pattern IS what it does
class CommandQueue { }         // Queue pattern IS what it does
```
</Good>

### Names Tell Domain Stories

Good names form sentences about business logic.

<Good>
```typescript
// Reads like domain language
user.authenticate()
order.calculateTotal()
payment.process()

// Not
user.executeAuthenticationStrategy()
order.runTotalCalculationAlgorithm()
payment.invokeProcessingWorkflow()
```
</Good>

## Quick Reference

| Bad Pattern | Why Bad | Good Alternative |
|-------------|---------|------------------|
| `ZodValidator` | Exposes implementation | `Validator` |
| `MCPToolWrapper` | Exposes protocol | `RemoteTool` |
| `NewUserAPI` | Temporal reference | `UserAPI` |
| `ImprovedParser` | References history | `Parser` |
| `ToolFactory` | Pattern name noise | `Tool` or `createTool()` |
| `AbstractToolInterface` | Redundant qualifiers | `Tool` |
| `executeToolWithValidation()` | Implementation in name | `execute()` |

## When Changing Code

**Rule:** Never document old behavior or the change in names.

<Bad>
```typescript
// During refactoring
class NewAuthService { }       // References the change
class ImprovedValidator { }    // References improvement
class UnifiedAPIClient { }     // References unification
```
</Bad>

<Good>
```typescript
// During refactoring
class AuthService { }          // What it is
class Validator { }            // What it does
class APIClient { }            // What it is
```
</Good>

## Red Flags - STOP and Rename

If you catch yourself writing:
- "New", "Old", "Legacy", "Improved", "Enhanced"
- "Unified", "Refactored", "Updated", "Modern"
- Implementation details ("Zod", "JSON", "MCP", "SQL")
- Unnecessary pattern names ("Factory", "Builder", "Manager")
- Redundant qualifiers ("Abstract", "Base", "Interface")

**STOP. Find a name describing actual purpose in the domain.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Need to distinguish from old version" | Old version shouldn't exist or should be in different namespace. |
| "New developers need to know it's improved" | Code quality shows in behavior, not names. |
| "Factory pattern is important here" | If pattern is core purpose, fine. Usually it's not. |
| "Everyone knows what Zod is" | Today they do. Names should outlive dependencies. |
| "It IS a wrapper around MCP" | That's implementation. What does it DO in your domain? |

## Verification

Before committing names:
- [ ] Name describes domain purpose
- [ ] No implementation details
- [ ] No temporal context
- [ ] No unnecessary pattern names
- [ ] Forms readable sentences with other code
- [ ] No "new", "old", "improved", "wrapper"

## Real-World Examples

### Bad Naming (Don't Do This)

```typescript
class ImprovedZodConfigValidator { }           // ❌ Temporal + implementation
const newAPIClientWithRetry = new Client();    // ❌ Temporal + implementation
function executeEnhancedToolFactory() { }      // ❌ Temporal + pattern noise

// Using them
const validator = new ImprovedZodConfigValidator();
validator.validateWithNewSchema();
```

### Good Naming

```typescript
class ConfigValidator { }                      // ✅ Domain purpose
const apiClient = new Client();               // ✅ What it is
function createTool() { }                     // ✅ What it does

// Using them - reads like domain language
const validator = new ConfigValidator();
validator.validate();
```

## Integration with Other Skills

**For tactical variable naming:** See @../naming-variables/SKILL.md for comprehensive variable naming techniques (optimal length, scope rules, conventions for booleans/collections/qualifiers, naming as diagnostic tool)

**For comment guidelines:** See @../writing-evergreen-comments/SKILL.md for keeping comments evergreen (no temporal context in comments either)
