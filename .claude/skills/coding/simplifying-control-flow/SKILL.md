---
name: Simplifying Control Flow
description: Flatten nested conditionals with early returns or table-driven methods - keep nesting depth under 3 levels
when_to_use: When writing conditional logic. When nesting depth exceeds 2-3 levels. When multiple conditions determine outcome. When similar if/else patterns repeat. When business rules encoded in nested ifs. When control flow is hard to follow. When nested if statements exist. When adding new cases requires deep surgery.
version: 1.0.0
languages: all
---

# Simplifying Control Flow

## Overview

Nested conditionals are hard to understand and error-prone. Flatten them.

**Core principle:** Nesting depth < 3 levels. Use early returns, table-driven methods, or extracted conditions.

## Baseline Violation

**Agents create nested if/else for multi-condition logic:**

❌ **Nested (baseline):**
```python
def calculate_discount(order_amount, is_vip):
    if is_vip:
        if order_amount > 1000:
            return 0.20
        elif order_amount > 500:
            return 0.15
    else:
        if order_amount > 1000:
            return 0.10
        elif order_amount > 500:
            return 0.05
    return 0.0
```

**Problems:** Duplicated logic, hard to see all tiers, adding tier requires finding nesting spot.

## Three Techniques

### 1. Flatten with Combined Conditions

✅ **All at same level:**
```python
def calculate_discount(order_amount, is_vip):
    if is_vip and order_amount > 1000: return 0.20
    if is_vip and order_amount > 500: return 0.15
    if order_amount > 1000: return 0.10
    if order_amount > 500: return 0.05
    return 0.0
```

### 2. Table-Driven (Best for Data)

✅ **Business rules as data:**
```python
DISCOUNT_TIERS = [
    (1000, 0.20, 0.10),  # min_amount, vip_rate, regular_rate
    (500,  0.15, 0.05),
]

def calculate_discount(order_amount, is_vip):
    for min_amount, vip_rate, regular_rate in DISCOUNT_TIERS:
        if order_amount > min_amount:
            return vip_rate if is_vip else regular_rate
    return 0.0
```

**When to use:** Pricing tiers, status transitions, configuration-driven logic.

### 3. Extract Complex Conditions

✅ **Named boolean for clarity:**
```python
def is_eligible(user, minimum):
    return (user.age >= 18 and user.verified_email and
            user.balance > minimum and not user.suspended)

if is_eligible(user, minimum_purchase):
    allow_purchase()
```

**When to use:** Complex boolean expressions, reused conditions.

## Quick Reference

| Problem | Solution |
|---------|----------|
| Nested if/else | Flatten with combined conditions OR table-driven |
| Deep nesting (>3) | Extract inner logic to function |
| Complex boolean | Extract to named function |
| Business rules | Table-driven method |
| Long if/elif chain | Table lookup OR polymorphism |

## Guard Clauses

**Baseline showed agents already use these well:**

```python
def validate(data):
    if not data:
        return False, "data required"  # Early return
    if data.amount <= 0:
        return False, "amount must be positive"  # Early return
    # Main logic here (no nesting)
```

**Keep using this pattern for validation and error cases.**

## Red Flags

- Nesting depth > 3
- Can't see matching braces without scrolling
- Duplicate conditions in nested blocks
- Adding new case touches multiple nesting levels

**Fix:** Flatten or use table-driven.

## Real-World Impact

From baseline:
- Agents created 2-level nesting for 4 discount tiers
- With table-driven: All tiers visible, easy to add/modify

## Integration with Other Skills

**For complex functions:** See @../keeping-routines-focused/SKILL.md - extract when nesting gets deep

**For reducing complexity:** See @../../architecture/reducing-complexity/SKILL.md - simpler control flow = less complexity
