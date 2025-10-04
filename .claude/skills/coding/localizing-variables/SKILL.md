---
name: Localizing Variables
description: Declare variables in smallest possible scope, initialize close to first use, minimize span and live time
when_to_use: When writing any code with variables. When variables are declared at top of function but used later. When related statements are scattered. When variable scope is larger than necessary. When you see long variable live times or large span between references. When can't find where variable is initialized. When variable has stale or unexpected value. When forgot to reset counter or accumulator. When initialization errors occur. When variables declared far from first use. When window of vulnerability is large. When must scroll to see variable declaration and usage. When reviewing pull requests with wide variable scope. When refactoring functions with many local variables.
version: 1.0.0
languages: all
type: technique
---

# Localizing Variables

## Overview

The Principle of Proximity: Keep related actions together. Declare variables in the smallest scope possible, initialize them close to where they're first used, and keep all references to a variable close together.

**Core principle:** Minimize the window of vulnerability. The smaller the scope and the closer the references, the less can go wrong and the easier code is to understand.

**Goal:** Reduce what you must keep in mind at any one time.

## When to Use

**Apply to every variable you declare:**
- When declaring variables
- When initializing variables
- When reviewing code with scattered variable usage
- When refactoring to improve clarity

**Warning signs:**
- Variables declared at top of function, used at bottom
- All variables initialized together, far from first use
- Large gap between variable declaration and use
- Must scroll to see variable declaration and usage together
- Variables have function/class scope when could be more local
- Can't see all uses of variable on one screen

## Key Concepts

### Scope

How widely visible a variable is:
- **Block scope** - visible only within `{}` or indented block (smallest)
- **Loop scope** - visible only within loop
- **Function scope** - visible throughout function
- **Class scope** - visible to all methods in class
- **Module scope** - visible throughout file
- **Global scope** - visible everywhere (largest, avoid)

**Rule:** Start with smallest scope. Expand only if necessary.

### Span

Distance between successive references to a variable:

```python
a = 0  # First reference
b = 0  # 1 line between references to a
c = 0  # 2 lines between references to a
a = b + c  # Second reference
# Span of a: 2 lines
```

**Goal:** Minimize span. Keep references close together.

### Live Time

Total statements between first and last reference:

```python
recordIndex = 0  # Line 2 - first reference
# ... 24 lines of other code ...
recordIndex += 1  # Line 28 - last reference
# Live time: 28 - 2 + 1 = 27 statements
```

**Goal:** Minimize live time. Reduce window of vulnerability.

## The Principle of Proximity

**Keep related actions together:**

❌ **Bad (declarations far from use):**
```python
def process_data():
    # All declarations at top
    index = 0
    total = 0
    done = False
    result = []

    # 20 lines later...
    while index < count:
        index += 1

    # 30 lines later...
    while not done:
        if total > threshold:
            done = True

    # 40 lines later...
    result.append(final_value)
    return result
```

**Live times:** index=25, total=35, done=35, result=40. Average: 34 lines.

✅ **Good (declare close to use):**
```python
def process_data():
    # Declare index right before loop that uses it
    index = 0
    while index < count:
        index += 1

    # Declare total and done right before loop that uses them
    total = 0
    done = False
    while not done:
        if total > threshold:
            done = True

    # Declare result right before use
    result = []
    result.append(final_value)
    return result
```

**Live times:** index=3, total=5, done=5, result=2. Average: 4 lines.

**Improvement:** 34 → 4 average live time (8.5x better)

## Aggressive Scope Minimization

### Technique 1: Declare at Point of First Use

Languages like C++, Java, Python, JavaScript allow this:

❌ **Bad:**
```python
def calculate_report():
    total = 0  # Declared at top
    count = 0
    average = 0.0

    # 10 lines later...
    total = sum(values)
    count = len(values)
    average = total / count if count > 0 else 0.0
```

✅ **Good:**
```python
def calculate_report():
    # 10 lines of other work...

    # Declare right before use
    total = sum(values)
    count = len(values)
    average = total / count if count > 0 else 0.0
```

### Technique 2: Use Block Scope

In languages supporting block scope, use it:

```python
# Process old data - variables scoped to this block
{
    old_data = get_old_data()
    old_total = sum(old_data)
    print_summary(old_data, old_total)
}  # old_data, old_total die here

# Process new data - fresh variables, no collision
{
    new_data = get_new_data()
    new_total = sum(new_data)
    print_summary(new_data, new_total)
}  # new_data, new_total die here
```

### Technique 3: Initialize at Declaration

❌ **Bad:**
```python
# Declare and initialize separately
user_count: int
user_count = 0

active_users: list
active_users = []
```

✅ **Good:**
```python
# Initialize when declaring
user_count = 0
active_users = []
```

### Technique 4: Use Loop-Scoped Variables

Many languages support declaring loop variables in the loop:

```python
# Variable i exists ONLY within this loop
for i in range(count):
    process(i)
# i doesn't exist here

# Another loop can use i without conflict
for i in range(other_count):
    process_other(i)
```

### Technique 5: Group Related Statements

Keep statements working with same variables together:

❌ **Bad (scattered):**
```python
old_data = get_old_data()
new_data = get_new_data()
old_total = sum(old_data)
new_total = sum(new_data)
print_old_summary(old_data, old_total)
print_new_summary(new_data, new_total)
```

**Must track 6 variables simultaneously**

✅ **Good (grouped):**
```python
# Group 1: Old data (track 2 variables)
old_data = get_old_data()
old_total = sum(old_data)
print_old_summary(old_data, old_total)

# Group 2: New data (track 2 variables)
new_data = get_new_data()
new_total = sum(new_data)
print_new_summary(new_data, new_total)
```

**Track only 2 variables at a time**

## Minimize Global/Class Variables

**Globals have enormous scope, span, and live time** - avoid them.

❌ **Bad:**
```python
total = 0  # Global

def add_to_total(value):
    global total
    total += value  # Total lives forever, visible everywhere

def get_total():
    global total
    return total
```

✅ **Good:**
```python
class Counter:
    def __init__(self):
        self._total = 0  # Private, encapsulated

    def add(self, value):
        self._total += value  # Scoped to class

    def get_total(self):
        return self._total
```

**Even better (eliminate state if possible):**
```python
def calculate_total(values):
    return sum(values)  # No state, no scope issues
```

## Measuring Improvement

### Calculate Span

Count lines between successive references:

```python
value = 10  # Reference 1
line_a()    # 1 line between
line_b()    # 2 lines between
result = value * 2  # Reference 2
# Span: 2 lines
```

**Target:** Average span < 5 lines

### Calculate Live Time

Count lines from first to last reference (inclusive):

```python
count = 0      # Line 5 - first reference
# ... code ...
count += 1     # Line 42 - last reference
# Live time: 42 - 5 + 1 = 38 lines
```

**Target:** Average live time < 10 lines

**Global variables:** Infinite live time (another reason to avoid)

## Common Mistakes

**❌ All variables at top (C-style):**
```python
def process():
    # Declare everything at top
    i = 0
    j = 0
    total = 0
    result = []
    temp = None

    # Use i 20 lines later
    for i in range(10):
        ...
```

**✅ Declare where used:**
```python
def process():
    # Use variables close to declaration
    for i in range(10):  # i scoped to loop
        ...

    total = 0  # Declared right before use
    for item in items:
        total += item
```

---

**❌ Wide scope when narrow would work:**
```python
def calculate():
    result = 0  # Function scope

    if condition_a:
        result = calculate_a()  # Could be block-scoped
        print(result)
    # result accessible here but not used

    if condition_b:
        result = calculate_b()  # Reusing same variable
        print(result)
```

✅ **Narrow scope:**
```python
def calculate():
    if condition_a:
        result = calculate_a()  # Block scope
        print(result)
    # result doesn't exist here

    if condition_b:
        result = calculate_b()  # Fresh variable, no collision
        print(result)
```

---

**❌ Long live time:**
```python
index = 0  # Line 2
# ... 50 lines of unrelated code ...
while index < count:  # Line 52 - finally used
    index += 1
# Live time: 51 lines
```

✅ **Short live time:**
```python
# ... 50 lines of other code ...

index = 0  # Line 52 - right before use
while index < count:
    index += 1
# Live time: 2 lines
```

## Practical Guidelines

### 1. Initialize at Declaration

Languages like C++, Java, Python, JavaScript support this:

```python
# ✅ Declare and initialize together
user_count = 0
active_users = get_active_users()
total_revenue = calculate_revenue(orders)
```

### 2. Loop Variables in Loop Declaration

```python
# ✅ Loop variable scoped to loop
for user in users:
    process(user)  # user exists only here

for item in items:
    handle(item)  # item exists only here
```

### 3. Initialize Before Loop, Not at Function Start

❌ **Bad:**
```python
def process_records():
    index = 0  # Line 2

    # 30 lines of other work...

    # Finally use index
    while index < record_count:  # Line 32
        index += 1
```

✅ **Good:**
```python
def process_records():
    # 30 lines of other work...

    # Initialize right before loop
    index = 0
    while index < record_count:
        index += 1
```

**Why:** When you modify code and add outer loop, initialization is correctly placed for re-initialization on each pass.

### 4. Extract Related Statements Into Routines

Long routines create large scope. Break into smaller routines:

```python
# ✅ Each routine has small scope
def process_old_data():
    old_data = get_old_data()  # Scoped to this routine only
    old_total = sum(old_data)
    return old_total

def process_new_data():
    new_data = get_new_data()  # Fresh variable, no collision
    new_total = sum(new_data)
    return new_total
```

Variables automatically die when routine exits.

### 5. Prefer Most Restricted Visibility

**Hierarchy (most restricted to least):**
1. Block/loop local (if language supports)
2. Function local
3. Private instance variable
4. Protected instance variable
5. Public instance variable
6. Module-level
7. Global

**Start at #1, move down only if necessary.**

## Convenience vs Intellectual Manageability

**Two philosophies:**

### Convenience Philosophy

"Make variables global so they're convenient to access anywhere. Don't fool around with parameter lists."

**Problem:** Easy to write, hard to read/maintain. Any routine can modify any variable. Must understand entire program to modify one part.

### Intellectual Manageability Philosophy

"Keep variables as local as possible. Hide information. Minimize what you must think about at once."

**Benefit:** Harder to write (must think about scope), easier to read/maintain. Can understand one routine without knowing all others.

**Code Complete's recommendation:** Favor intellectual manageability. Code is read 10x more than written.

## Example Transformation

**❌ Before (wide scope, long live time):**
```python
def summarize_data():
    # All variables at top with function scope
    old_data = None
    num_old = 0
    total_old = 0
    new_data = None
    num_new = 0
    total_new = 0

    old_data = get_old_data()  # Line 8
    num_old = len(old_data)
    total_old = sum(old_data)
    print_summary(old_data, total_old, num_old)  # Line 11
    save_summary(total_old, num_old)

    new_data = get_new_data()  # Line 14
    num_new = len(new_data)
    total_new = sum(new_data)
    print_summary(new_data, total_new, num_new)  # Line 17
    save_summary(total_new, num_new)
```

**Must track 6 variables throughout entire function. Live times: old_data=4, new_data=4, etc.**

✅ **After (narrow scope, short live time):**
```python
def summarize_data():
    # Group 1: Old data (variables live only 4 lines)
    old_data = get_old_data()
    num_old = len(old_data)
    total_old = sum(old_data)
    print_summary(old_data, total_old, num_old)
    save_summary(total_old, num_old)
    # old_data, num_old, total_old mentally "die" here

    # Group 2: New data (fresh variables, 4 lines)
    new_data = get_new_data()
    num_new = len(new_data)
    total_new = sum(new_data)
    print_summary(new_data, total_new, num_new)
    save_summary(total_new, num_new)
```

**Track 3 variables at a time. Same live times, but mental load reduced.**

✅ **Even better (extract to routines):**
```python
def summarize_data():
    process_old_data()  # Variables scoped inside
    process_new_data()  # Variables scoped inside

def process_old_data():
    # Variables live only in this routine (5 lines)
    old_data = get_old_data()
    num_old = len(old_data)
    total_old = sum(old_data)
    print_summary(old_data, total_old, num_old)
    save_summary(total_old, num_old)
    # Variables die when routine exits
```

**Track 3 variables maximum. Variables automatically cleaned up.**

## Quick Reference

| Situation | Technique | Example |
|-----------|-----------|---------|
| **Loop variable** | Declare in loop | `for i in range(n):` |
| **Temporary calculation** | Inline or immediate use | `total = sum(values)` right before `print(total)` |
| **Used in one block** | Declare in that block | if-block variable stays in if-block |
| **Used across function** | Function-local only if necessary | Don't make it class/global |
| **Shared across methods** | Private instance variable | Not public unless necessary |
| **Truly global** | Access routine instead | Wrap in getter/setter |

## Common Patterns

### Pattern 1: Loop Counters

```python
# ✅ Counter scoped to loop
for i in range(len(items)):
    process(items[i])
# i doesn't exist here - good

# Can reuse i in another loop without collision
for i in range(len(others)):
    process(others[i])
```

### Pattern 2: Calculation Results

```python
# ✅ Calculate right before use
def generate_report():
    # Other work...

    # Calculate only when needed, use immediately
    total_revenue = sum(order.total for order in orders)
    print(f"Total Revenue: ${total_revenue}")

    # Different calculation later
    active_user_count = len([u for u in users if u.is_active])
    print(f"Active Users: {active_user_count}")
```

### Pattern 3: Temporary Values

```python
# ✅ Temporary lives only 2-3 lines
def swap_values(arr, i, j):
    temp = arr[i]  # Temporary variable
    arr[i] = arr[j]
    arr[j] = temp  # temp used and done (live time: 3 lines)
```

### Pattern 4: Iteration State

```python
# ✅ State variables near the loop they control
def process_until_done():
    # Other work...

    # Declare state right before loop
    done = False
    attempts = 0
    while not done and attempts < max_attempts:
        done = try_process()
        attempts += 1
```

## Measuring Your Code

Calculate average span and live time for a function:

```python
def example():
    a = 0      # Line 2, ref 1
    b = 0      # Line 3
    c = 0      # Line 4
    a = b + c  # Line 5, ref 2 of a
    d = a * 2  # Line 6, ref 3 of a

# Span of a: (5-2=3) + (6-5=1) = 4, average 2
# Live time of a: 6-2+1 = 5 lines
```

**Good metrics:**
- Average span: < 5 lines
- Average live time: < 10 lines

**If higher:** Consider localizing more aggressively.

## Benefits

### 1. Reduces Window of Vulnerability

Shorter live time = fewer lines where variable could be incorrectly modified:

```python
# Live time = 50 lines
value = 0  # Line 1
# ... 48 lines where value could be accidentally changed ...
return value  # Line 50

vs.

# Live time = 2 lines
value = calculate()  # Line 49
return value  # Line 50 - less can go wrong
```

### 2. Easier to Understand

Seeing declaration and usage together aids comprehension:

```python
# ✅ See both on one screen
count = len(items)
print(f"Processing {count} items")

# ❌ Must scroll to see declaration
# ... Line 1: count = 0
# ... 50 lines later...
# ... Line 51: print(f"Processing {count} items")  # What's count?
```

### 3. Reduces Initialization Errors

Variables initialized close to use are less likely to have stale values:

```python
# ✅ Initialized fresh each loop iteration
for batch in batches:
    count = 0  # Reset for each batch
    for item in batch:
        count += 1
```

vs.

```python
# ❌ Might forget to reset
count = 0  # Top of function
for batch in batches:
    # Forgot to reset count - accumulates across batches!
    for item in batch:
        count += 1
```

### 4. Easier Refactoring

Short live time makes extracting to separate routine easier:

```python
# Related statements with short-lived variables
# are easy to extract into their own routine
old_data = get_old_data()  # Lines 10-13
old_total = sum(old_data)
print_summary(old_data, old_total)
# → Extract to process_old_data() routine
```

## Quick Checklist

For each variable, ask:

- [ ] Is this declared in smallest possible scope?
- [ ] Could it be loop-scoped instead of function-scoped?
- [ ] Could it be function-local instead of class-level?
- [ ] Is it initialized close to first use?
- [ ] Are all references to it close together?
- [ ] Could I extract this section into a routine to reduce scope further?
- [ ] If class/global variable: could it be passed as parameter instead?

**If any answer is "yes, could be smaller" → localize it.**

## Real-World Impact

From Code Complete:
- Research shows shorter live times correlate with fewer errors
- Proximity aids comprehension
- Local scope prevents unintended side effects
- Baseline test: agent declared all variables at top (live time ~15-25 lines)
- Better practice: average live time < 10 lines

**Key insight:** The more you can hide, the less you must keep in mind. The less in mind, the fewer errors.

## Integration with Other Skills

**For initialization:** See patterns in @../designing-before-coding/SKILL.md for thinking about data initialization early in design

**For naming:** See @../naming-variables/SKILL.md - short-lived local variables can have shorter names; longer-lived variables need more descriptive names
