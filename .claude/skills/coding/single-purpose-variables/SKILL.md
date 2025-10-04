---
name: Single Purpose Variables
description: Use each variable for exactly one purpose - no hybrid coupling or hidden meanings
when_to_use: When writing any code with variables. When variable represents different things at different times. When -1 or special values indicate errors. When reusing temp for unrelated purposes. When variable meaning changes. When hybrid coupling exists. When pageCount=-1 means error not count.
version: 1.0.0
languages: all
---

# Single Purpose Variables

## Overview

Each variable should represent exactly ONE thing. No reusing for different purposes. No hidden meanings.

**Core principle:** If variable represents count sometimes and error other times, use two variables.

## Baseline Violation: Hybrid Coupling

**From baseline, agents use special values to indicate errors:**

❌ **Hybrid coupling (baseline):**
```python
def process_file_pages(filename):
    try:
        pages_processed = 0  # Count (integer purpose)
        # ... processing ...
        return pages_processed
    except:
        return -1  # Error flag (boolean purpose as -1)
```

**Problem:** `pages_processed` represents TWO things:
- Non-negative integer = page count
- -1 = error occurred

**This is hybrid coupling:** Variable moonlights as different type.

✅ **Separate concerns:**
```python
def process_file_pages(filename):
    try:
        pages_processed = 0
        # ... processing ...
        return (True, pages_processed)  # Success, count
    except Exception as e:
        return (False, str(e))  # Failure, error message
```

**Or raise exception:**
```python
def process_file_pages(filename):
    # Let exceptions propagate - no hybrid variable needed
    pages_processed = 0
    # ... processing (raises on error) ...
    return pages_processed  # Always a count, never an error
```

## Common Hidden Meanings

❌ **What agents naturally do:**

```python
page_count = 15  # Number of pages
page_count = -1  # Wait, now it means error!

customer_id = 1234  # Customer number
customer_id = 500001  # Wait, > 500000 means delinquent (subtract 500000)!

bytes_written = 1024  # Bytes written
bytes_written = -5  # Wait, negative means disk drive number!
```

✅ **Separate variables:**
```python
page_count = 15
processing_failed = True  # Separate boolean for error state

customer_id = 1234
is_delinquent = False  # Separate boolean for status

bytes_written = 1024
disk_drive = 5  # Separate variable for drive number
```

## Legitimate Variable Reuse

**Good reuse (same purpose, same meaning):**

```python
# ✅ GOOD: total_sales used for multiple related calculations
total_sales = sum(sales)
average = total_sales / len(sales)  # Same value, same meaning
percentage = (total_sales / target) * 100  # Same value, same meaning
```

**Bad reuse (different purposes):**

```python
# ❌ BAD: temp reused for unrelated purposes
temp = sqrt(b*b - 4*a*c)  # Discriminant
root1 = (-b + temp) / (2*a)
# ...
temp = root1  # Now reused for swapping (different purpose!)
root1 = root2
root2 = temp
```

✅ **Separate variables:**
```python
discriminant = sqrt(b*b - 4*a*c)  # Clear purpose
root1 = (-b + discriminant) / (2*a)
# ...
old_root = root1  # Clear purpose (swapping)
root1 = root2
root2 = old_root
```

## Quick Reference

| Violation | Example | Fix |
|-----------|---------|-----|
| **Hybrid coupling** | `count=-1` means error | Separate: count + error_occurred boolean |
| **Hidden meanings** | `id > 500000` means delinquent | Separate: id + is_delinquent |
| **Temp reuse** | `temp` for discriminant, then swapping | Use: discriminant, old_root |
| **State changes** | Variable means X, then means Y | Two variables with clear names |

## Red Flags

- Variable represents different types (integer sometimes, boolean as -1)
- Special values have hidden meanings (-1, 0, null mean different things)
- Reusing `temp`, `result`, `value` for unrelated purposes
- Code comments explain "if X then it means Y, else Z"
- Must remember what value currently means

**Fix:** Create separate variable with clear name for each purpose.

## Real-World Impact

From Code Complete:
- Hybrid coupling creates confusion
- Even if clear to you, won't be to others
- Extra variable costs nothing, clarity is priceless

From baseline:
- Agent used `-1` to indicate error in count variable (hybrid coupling)

**With this skill:** Separate variables for separate purposes.

## Integration with Other Skills

**For naming clarity:** See @../naming-variables/SKILL.md - each purpose needs its own well-named variable
