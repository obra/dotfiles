---
name: Exploring Alternatives
description: Try 2-3 different approaches before implementing - don't settle for first design you think of
when_to_use: Before implementing any non-trivial solution. When you have your first idea and are ready to code. When solution feels complex. When choosing between approaches. When stuck on a design. When tempted to implement first idea immediately. When asking "is this the best approach?". When wondering "should I use library or custom code?". When evaluating trade-offs. When solution feels forced or awkward. When didn't consider alternatives. When implementation is fighting you. When choosing data structures or algorithms. When design decision needs justification. When comparing manual implementation vs using library. When solution has multiple viable paths.
version: 1.0.0
languages: all
type: technique
---

# Exploring Alternatives

## Overview

Don't settle for the first design you think of. Try multiple approaches, compare trade-offs, pick the best, THEN implement.

**Core principle:** Design is cheap to iterate. Code is expensive. Once you write code, emotional attachment makes it hard to throw away. Explore alternatives while iteration is still cheap.

**Violating the letter of this rule is violating the spirit of good design.**

## When to Use

**Always use before implementing:**
- Non-trivial features
- Complex algorithms
- System design decisions
- Refactoring approaches
- Architecture choices
- Data structure selection

**Especially when:**
- First idea feels complex
- Multiple viable approaches exist
- Stakes are high (production code, public APIs)
- Design will be hard to change later

**Warning signs you need this:**
- Jumping to implementation with first idea
- "This is the obvious way" (without considering alternatives)
- Solution feels forced or awkward
- Fighting the implementation
- Design keeps changing during coding

## The Exploration Process

### Step 1: Understand the Problem

**Before exploring solutions, clarify the problem:**

- What exactly are we solving?
- What are the constraints?
- What are the requirements?
- What are success criteria?

**If problem is unclear, exploring solutions is premature.**

### Step 2: Generate 2-3 Alternatives

**Don't stop at first idea. Generate at least 2 more.**

**Techniques for generating alternatives:**

1. **Different data structures:**
   - Array vs linked list vs tree vs hash table
   - List vs set vs dictionary

2. **Different algorithms:**
   - Iterative vs recursive
   - Brute force vs optimized
   - Different algorithmic approaches (sort-based vs hash-based)

3. **Different levels of abstraction:**
   - Direct implementation vs library
   - Custom code vs existing pattern
   - Simple specific vs generic flexible

4. **Different responsibility allocation:**
   - One class vs multiple
   - Function vs class
   - Inline vs extracted

5. **Different error handling:**
   - Exceptions vs return codes
   - Fail fast vs continue with defaults
   - Validate at boundary vs trust callers

**For each approach, sketch it in pseudocode or bullet points.**

### Step 3: Compare Trade-offs

**Evaluate each alternative against criteria:**

| Criterion | Alternative 1 | Alternative 2 | Alternative 3 |
|-----------|---------------|---------------|---------------|
| Simplicity | Simple | Complex | Medium |
| Performance | Fast | Slow | Medium |
| Maintainability | Easy to modify | Hard to change | Medium |
| Testability | Easy to test | Hard to test | Medium |
| Flexibility | Rigid | Very flexible | Some flex |
| Development time | Quick | Slow | Medium |

**Which criteria matter most for this problem?**

### Step 4: Pick the Best

**Choose based on:**
- Requirements (which criteria actually matter)
- Simplicity (default to simplest that meets requirements)
- Long-term maintainability (code is read 10x more than written)

**Document why you picked it:**
- "Chose approach 2 because performance is critical and measurements show approach 1 is too slow"
- "Chose approach 1 because simplicity matters more than flexibility we don't need yet"

### Step 5: Implement

Only after comparing alternatives, implement the chosen approach.

**If implementation fights you → return to Step 2. You might have picked wrong alternative.**

## Quick Reference

| When | What to Explore | Example Alternatives |
|------|-----------------|----------------------|
| **Data structure choice** | Different structures | Array, LinkedList, HashMap, Tree |
| **Algorithm choice** | Different algorithms | Iterative, Recursive, Different approach |
| **Error handling** | Different strategies | Exceptions, Return codes, Defaults |
| **Responsibility** | Different decompositions | One class, Multiple classes, Functions |
| **Abstraction level** | Build vs use | Custom implementation, Library, Framework |
| **Complexity trade-off** | Simple vs flexible | Specific solution, Generic solution |

## Example: Validation Function

**Problem:** Validate user registration data

### Alternative 1: Manual Validation

```python
def validate_registration(data: dict) -> tuple[bool, str]:
    if 'email' not in data:
        return False, "Missing email"
    if not re.match(email_pattern, data['email']):
        return False, "Invalid email"
    # ... validate each field manually
```

**Trade-offs:**
- ✅ Simple, no dependencies
- ✅ Full control
- ❌ Verbose, repetitive
- ❌ Easy to miss fields

### Alternative 2: Pydantic Model

```python
from pydantic import BaseModel, EmailStr, Field

class RegistrationData(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    username: str
    age: int = Field(ge=18)

def validate_registration(data: dict) -> tuple[bool, str]:
    try:
        RegistrationData(**data)
        return True, ""
    except ValidationError as e:
        return False, str(e)
```

**Trade-offs:**
- ✅ Declarative, clear
- ✅ Comprehensive validation
- ✅ Less code
- ❌ Adds dependency
- ❌ Learning curve for library

### Alternative 3: Validator Class

```python
class RegistrationValidator:
    def __init__(self, data):
        self.data = data
        self.errors = []

    def validate(self):
        self._validate_email()
        self._validate_password()
        self._validate_username()
        self._validate_age()
        return len(self.errors) == 0, ", ".join(self.errors)

    def _validate_email(self):
        # Focused validation method
```

**Trade-offs:**
- ✅ Organized, testable
- ✅ Easy to extend
- ✅ No dependencies
- ❌ More boilerplate
- ❌ Over-engineering for simple case

### Comparison

**For this problem:**
- If project already uses Pydantic: Choose Alternative 2
- If no dependencies allowed: Choose Alternative 1
- If validation will grow complex: Choose Alternative 3

**By exploring all three, you make informed decision instead of defaulting to first idea.**

## Common Mistakes

**❌ Implementing first idea:**
```
Think of approach → implement immediately → discover problems → hack fixes
```

**✅ Exploring alternatives:**
```
Think of approach → sketch it → think of alternative → sketch it → compare → pick best → implement cleanly
```

---

**❌ "This is obviously the best way":**

Without exploring, you don't know if it's best. Your "obvious" solution might be suboptimal.

**✅ "Let me try two other approaches to confirm this is best":**

Even if first idea wins, exploring validates your choice.

---

**❌ Exploring in code:**

Writing full implementations of multiple approaches wastes time and creates emotional attachment.

**✅ Exploring in pseudocode/sketches:**

Quick, cheap, easy to discard.

## If You Already Implemented First Idea

**You implemented without exploring alternatives. Now what?**

**No exceptions:**
- Don't claim "it works so it's fine"
- Don't skip exploration "to save time"
- Don't just document why you picked this approach (you didn't pick, you defaulted)

**Required steps:**

1. **Acknowledge the sunk cost** - Hours spent are already gone
2. **Sketch 2 alternatives** - Don't look at your implementation while sketching
3. **Include current implementation as Alternative 1** - Describe what it does
4. **Compare all 3 honestly** - Is your implementation actually the best?
5. **Decide:**
   - If current code is best approach: Keep it, document the alternatives you rejected
   - If different approach is better: Implement it (sunk cost is already sunk)

**This isn't punishment. It's good engineering.**

Working code that's not the best approach = technical debt. Pay it now or pay interest later.

**Time investment:**
- Sketch 2 alternatives: 5 minutes
- Compare: 3 minutes
- Decision: 1 minute
- Total: 9 minutes to validate you chose well (or discover you didn't)

**9 minutes now vs hours of maintenance later.**

## Red Flags - STOP and Explore

**Before implementing:**
- First idea → ready to code (haven't explored alternatives)
- "This is the obvious approach" (without checking others)
- "Let's try this and see" (no comparison with alternatives)
- Solution feels forced (might be wrong approach)
- Can't articulate why this approach over others

**During implementing:**
- Fighting the implementation (wrong approach chosen?)
- Discovering limitations you didn't foresee
- Adding hack after hack to make it work
- Implementation much more complex than expected

**All of these mean: Stop. Explore alternatives in pseudocode.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "First idea is obviously best" | Without exploring, you don't know. Try 2 more anyway. |
| "Don't want to waste time" | 5 minutes exploring saves hours of bad implementation. |
| "This approach already works" | Working ≠ best. Other approaches might be simpler. |
| "I'm experienced, I know the right approach" | Experience creates bias. Check your intuition. |
| "Problem is too simple to need alternatives" | Even simple problems benefit. Takes 2 minutes. |
| "Already started coding, too late" | Sunk cost fallacy. Still cheaper to explore now than debug later. |
| "Other approaches won't work" | How do you know without trying them? |

## Verification Checklist

Before marking design complete:

- [ ] Sketched at least 2 alternative approaches (3+ for critical code)
- [ ] Compared alternatives against relevant criteria
- [ ] Can articulate why chosen approach is best
- [ ] Documented trade-offs considered
- [ ] Consciously rejected other approaches (not just ignored them)

**Can't check all boxes? Return to Step 2 (generate alternatives).**

## When to Stop Exploring

**Explore 2-3 alternatives minimum. Stop when:**

1. **Clear winner emerges** - One approach obviously superior for your criteria
2. **Diminishing returns** - Alternative 4 and 5 aren't meaningfully different
3. **Good enough found** - Approach meets requirements simply and clearly

**Don't:**
- Stop at first idea (always explore at least 2)
- Explore forever (analysis paralysis)
- Explore 10 alternatives (2-3 usually sufficient)

**Balance:** Enough exploration to find good solutions, not so much you never implement.

## Quick Exploration Template

```markdown
## Problem
[State the problem clearly]

## Alternative 1: [Name]
[Sketch the approach]
Pros: ...
Cons: ...

## Alternative 2: [Name]
[Sketch the approach]
Pros: ...
Cons: ...

## Alternative 3: [Name]
[Sketch the approach]
Pros: ...
Cons: ...

## Decision
Chose [Alternative X] because [reasoning based on requirements and trade-offs]
```

**Use this template when designing non-trivial solutions.**

## Real-World Impact

From Code Complete:
- "Don't settle for the first design you think of"
- Design is nondeterministic - multiple valid solutions exist
- Trying alternatives in pseudocode is cheap
- Design mistakes caught before coding save time

From baseline testing:
- Agents implemented first idea immediately
- No evidence of exploring alternatives
- No consideration of libraries (Pydantic for validation)
- No comparison of approaches
- Grade: F for iteration

**With this skill:** Systematic exploration before implementation.

## Integration with Other Skills

**For design iteration:** See @../designing-before-coding/SKILL.md - exploring alternatives happens during the pseudocode phase (Step 7)

**For complexity:** See @../../architecture/reducing-complexity/SKILL.md - simpler alternatives reduce complexity
