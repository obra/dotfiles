---
name: Refactoring Safely
description: Refactor with tests first, one change at a time, never mix refactoring with bug fixes or new features
when_to_use: Before refactoring any code. When improving code structure or naming. When extracting methods or classes. When code review requests changes. When you discover a bug during refactoring. When tempted to "fix while I'm here". When making multiple changes at once. When refactoring without tests. When mixing behavior changes with structure changes. When combining bug fix with refactoring. When extracting multiple methods simultaneously. When tests don't exist for code being refactored. When scope creep during refactoring.
version: 1.0.0
languages: all
---

# Refactoring Safely

## Overview

Refactoring means changing code structure without changing behavior. Safe refactoring requires tests first, one change at a time, and NEVER mixing refactoring with bug fixes or features.

**Core principle:** Refactoring changes HOW code works internally. Bug fixes change WHAT code does. Never mix HOW and WHAT changes.

**Violating the letter of this rule is violating the spirit of safe refactoring.**

## When to Use

**Use before any refactoring:**
- Improving names
- Extracting methods/classes
- Reducing complexity
- Improving structure
- Code review feedback

**Critical moments:**
- When you discover a bug during refactoring
- When tempted to "add this feature while I'm here"
- When making multiple structural changes
- When refactoring without tests

## The Iron Laws of Safe Refactoring

```
LAW 1: TESTS BEFORE REFACTORING (NO EXCEPTIONS)
LAW 2: ONE CHANGE AT A TIME
LAW 3: NEVER MIX REFACTORING WITH BUG FIXES OR FEATURES
```

Violating any law makes refactoring unsafe.

## Law 1: Tests Before Refactoring

**Before refactoring ANY code, you MUST have passing tests.**

**No exceptions:**
- Don't refactor "and add tests after"
- Don't "manually verify" instead of automated tests
- Don't "trust that it works"
- Don't refactor untested code without adding tests first

**Process:**

1. **If tests exist and pass:** Proceed with refactoring
2. **If tests exist but fail:** Fix tests first, THEN refactor
3. **If no tests exist:** STOP. Add tests. Watch them pass. THEN refactor.

❌ **Without tests (from baseline):**
```python
# Refactor immediately
def calc(x, y, z):  # Bad names
    ...

# Refactor to:
def calculate_capped_product(first, second, multiplier):
    ...
# Hope it still works!
```

✅ **With tests first:**
```python
# Step 1: Add tests
def test_calc():
    assert calc(2, 3, 4) == 20
    assert calc(10, 20, 5) == 100  # Capped
    # Run - ALL PASS

# Step 2: Refactor
def calculate_capped_product(first, second, multiplier):
    sum_of_addends = first + second
    uncapped = sum_of_addends * multiplier
    return min(uncapped, 100)

# Step 3: Run tests again - VERIFY STILL PASS
```

**Tests prove refactoring didn't break behavior.**

## Law 2: One Change at a Time

**Make ONE structural change. Test. Commit. Repeat.**

**Don't:**
- Extract 6 methods simultaneously
- Rename variables AND extract methods together
- Change structure AND algorithms together

**Do:**
- Extract method A. Test. Commit.
- Extract method B. Test. Commit.
- Rename variable X. Test. Commit.

❌ **Multiple changes (risky):**
```python
# Change 1: Extract validation
# Change 2: Extract calculation
# Change 3: Extract persistence
# Change 4: Rename variables
# Change 5: Reorder statements
# Change 6: Add error handling

# If tests fail: which change broke it?
```

✅ **Incremental (safe):**
```python
# Change 1: Extract validation
def validate_order(data):
    ...
# Run tests → PASS → Commit

# Change 2: Extract calculation
def calculate_total(items):
    ...
# Run tests → PASS → Commit

# If any test fails: know exactly which change broke it
```

**From baseline:** Agent chose incremental approach correctly. Skill reinforces this.

## Law 3: Never Mix Refactoring with Bug Fixes

**This is the critical discipline most developers violate.**

**Refactoring = change structure, preserve behavior**
**Bug fix = change behavior to correct it**

**Never do both in the same commit.**

### The Temptation (From Baseline Test 3)

You're refactoring and discover a bug:

```python
# Extracting validation from larger function
def validate_order_items(order_data):
    if not order_data.get('items'):
        return None  # ← BUG: should raise error
```

**Tempting reasoning:**
- "I'm touching this code anyway"
- "It's a trivial fix"
- "Efficient to fix while I'm here"
- "One coherent change"

**Why this is WRONG:**

1. **Diagnosis confusion:** If tests fail after your commit, is it because:
   - Refactoring broke something?
   - Bug fix was wrong?
   - Impossible to tell when mixed

2. **Review confusion:** Reviewer must evaluate:
   - Is the refactoring good?
   - Is the bug fix correct?
   - Mixed changes are harder to review

3. **Revert problems:** If bug fix is wrong, reverting loses good refactoring

4. **Violates single-change principle:** One commit = one purpose

### The Correct Approach

**When you discover a bug during refactoring:**

```
STOP refactoring immediately
STASH or commit refactoring work-in-progress
FIX the bug:
  - Write failing test for bug
  - Fix bug
  - Verify test passes
  - Commit bug fix separately
UNSTASH and continue refactoring
```

**Concrete example:**

```bash
# You're refactoring, discover bug
git stash  # Save refactoring work

# Fix bug in separate commit
# 1. Write test
def test_empty_items_raises_error():
    with pytest.raises(ValueError):
        validate_order_items({'items': []})
# Run - FAILS (bug exposed)

# 2. Fix bug
def validate_order_items(order_data):
    if not order_data.get('items'):
        raise ValueError("Order must have items")  # Fixed
# Run - PASSES

# 3. Commit bug fix separately
git add test_orders.py orders.py
git commit -m "fix: validate_order_items raises error for empty items"

# Now continue refactoring
git stash pop
# Continue extraction work
```

**Result:** Two clean commits:
1. Bug fix (behavior change)
2. Refactoring (structure change)

**Each can be reviewed, tested, reverted independently.**

## The Refactoring Process

### Step 1: Ensure Tests Exist and Pass

**Before touching any code:**

- [ ] Tests exist for code being refactored?
- [ ] All tests pass?
- [ ] Test coverage is adequate?

**If any "no" → add tests first, watch them pass, THEN refactor.**

### Step 2: Make ONE Structural Change

**Pick smallest possible refactoring:**
- Extract one method
- Rename one variable
- Move one piece of code
- Simplify one conditional

**Not:**
- Extract all methods
- Rename all variables
- Reorganize entire file

### Step 3: Run Tests

**After the change:**
- Run full test suite
- Verify all tests still pass
- If fail: undo change, understand why, try again

### Step 4: Commit

**If tests pass:**
- Commit the single refactoring change
- Clear commit message: "refactor: extract validation method"

### Step 5: Repeat

**For next refactoring:**
- Make next single change
- Test
- Commit
- Repeat until refactoring complete

## Discovered Bug During Refactoring

**From baseline test 3: Agents want to fix bugs while refactoring.**

**NO EXCEPTIONS - Separate the bug fix:**

```markdown
1. STOP refactoring
2. Stash or commit current refactoring work-in-progress
3. Fix bug:
   - Write failing test
   - Fix bug
   - Verify test passes
   - Commit bug fix separately ("fix: ...")
4. Return to refactoring:
   - Unstash work
   - Continue with structural changes
   - Commit refactoring separately ("refactor: ...")
```

**Even if:**
- Bug is trivial (one line)
- You're touching that exact code
- Seems "efficient" to combine
- "Just while I'm here"

**DON'T MIX THEM.**

**Baseline rationalization:** "The bug is right there, trivial fix, same code I'm touching"

**Reality:** Trivial bugs still change behavior. Behavior changes ≠ structural changes. Separate them.

## Discovered Feature Opportunity During Refactoring

**Same principle applies:**

While refactoring, you think "we should add error logging here."

**NO. Don't add features during refactoring.**

1. Note the idea
2. Finish refactoring
3. Commit refactoring
4. THEN add feature in separate commit

**Why:** Same diagnosis/review/revert problems as mixing bug fixes.

## Incremental Refactoring Pattern

**For large refactorings (300-line function → multiple smaller ones):**

**From baseline:** Agent correctly chose incremental approach.

✅ **Incremental (correct):**
```
Extract section 1 → test → commit
Extract section 2 → test → commit
Extract section 3 → test → commit
...
```

**Benefits:**
- Each commit is deployable
- Tests identify which extraction broke something
- Can stop midway if needed
- Progress is visible and safe

❌ **All-at-once (risky):**
```
Extract all 6 sections → test → commit
```

**Problems:**
- If tests fail, which extraction broke it?
- Can't deploy until all done
- All-or-nothing approach

**Always choose incremental.**

## Common Mistakes

**❌ Refactoring without tests:**
```
"It's simple, I can verify manually"
```

**✅ Tests first, always:**
```
Add tests → watch pass → refactor → verify still pass
```

---

**❌ Mixing refactoring + bug fix:**
```
# One commit with both structure change AND behavior change
"refactor: extract validation and fix null handling"
```

**✅ Separate commits:**
```
Commit 1: "fix: validate_order_items raises error for empty items"
Commit 2: "refactor: extract validate_order_items method"
```

---

**❌ Multiple changes in one commit:**
```
Extract 6 methods, rename 5 variables, reorder statements
```

**✅ One change per commit:**
```
Commit 1: Extract method A
Commit 2: Extract method B
...
```

## Red Flags - STOP Refactoring

**Before starting:**
- No tests exist
- Tests fail
- Coverage is inadequate
- Not sure how code behaves

**During refactoring:**
- Discovered a bug
- Found a feature opportunity
- Making multiple changes simultaneously
- Tests failing and not sure why
- Tempted to "fix while I'm here"

**All of these mean: STOP current refactoring, address the issue separately.**

## Common Rationalizations

From baseline testing:

| Excuse | Reality |
|--------|---------|
| "Bug is trivial, fix while refactoring" | Trivial bugs still change behavior. Separate commits. |
| "I'm touching this code anyway" | Touching ≠ should mix. Separate behavior from structure changes. |
| "Efficient to combine" | Efficient to write ≠ efficient to debug/review/revert. |
| "One coherent change" | No - one is behavior, one is structure. Different concerns. |
| "Tests will catch any issues" | Tests catch breaks, but can't tell which change broke it. |
| "Just while I'm here" | "While I'm here" scope creep ruins clean refactoring. |

## Verification Checklist

Before starting refactoring:

- [ ] Tests exist and pass
- [ ] Tests cover code being refactored
- [ ] One refactoring change identified (not multiple)
- [ ] No bug fixes or features mixed in

After each refactoring change:

- [ ] Ran full test suite
- [ ] All tests still pass
- [ ] Committed single change
- [ ] Commit message clear: "refactor: ..."

If discovered bug/feature:

- [ ] Stopped refactoring
- [ ] Stashed or committed WIP
- [ ] Handled bug/feature separately
- [ ] Returned to refactoring after

## Quick Reference

| Situation | Action |
|-----------|--------|
| **No tests** | Add tests first, watch pass, then refactor |
| **Tests fail** | Fix tests first, then refactor |
| **Large refactoring** | Break into small steps, test after each |
| **Bug discovered** | Stop, stash, fix bug separately, resume |
| **Feature idea** | Note it, finish refactoring, add feature after |
| **Multiple changes planned** | Do one, test, commit, repeat |

## Real-World Impact

From Code Complete:
- Refactoring is part of construction, not separate phase
- Make small changes, verify each step
- Tested refactoring is safe refactoring

From baseline testing:
- Agents correctly wrote tests first (good baseline)
- Agents correctly chose incremental for large refactorings (good baseline)
- Agents mixed bug fixes with refactoring (VIOLATION - the gap)

**With this skill:** Reinforce good practices, prevent mixing concerns.

## Integration with Other Skills

**For test discipline:** See @../../testing/test-driven-development/SKILL.md - tests before ANY code change, including refactoring

**For bug fixes:** See @../../debugging/systematic-debugging/SKILL.md - bug fixes require root cause investigation, separate from refactoring

**For focused routines:** See @../keeping-routines-focused/SKILL.md - extraction is a common refactoring, do it incrementally
