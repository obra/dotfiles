---
name: Commenting Intent
description: Comment WHY code exists and non-obvious decisions, not WHAT code does (mechanics)
when_to_use: When adding comments to code. When explaining complex algorithms. When documenting decisions. When code review requests more comments. When over-commenting obvious code. When comments just restate code. When magic numbers exist. When non-obvious decisions made. When future maintainer would ask "why this way?".
version: 1.0.0
languages: all
---

# Commenting Intent

## Overview

Good comments explain WHY, not WHAT. Code already shows what it does. Comments should explain intent, decisions, and non-obvious reasoning.

**Core principle:** If the comment just restates the code, delete the comment or improve the code.

## Baseline Violation

**Agents comment mechanics (what code does):**

❌ **Over-commenting (baseline):**
```python
# Calculate subtotal by multiplying price and quantity for each item, then summing
subtotal = sum(item.price * item.quantity for item in items)

# Calculate tax amount based on the subtotal and tax rate
tax = subtotal * tax_rate

# Calculate final total by adding subtotal and tax
total = subtotal + tax
```

**Problem:** Comments just restate obvious code. No value added.

✅ **Comment intent only:**
```python
def calculate_total_price(items, tax_rate):
    """Calculate order total including tax."""
    subtotal = sum(item.price * item.quantity for item in items)
    tax = subtotal * tax_rate
    return subtotal + tax  # No comments needed - code is clear
```

## What to Comment

### 1. Non-Obvious Decisions

✅ **WHY you chose this approach:**
```python
def is_rate_limited(user_id, redis_client):
    # Using Redis instead of in-memory to support distributed rate limiting
    # across multiple app servers. Limit: 100 req/min per business requirements.
    key = f"rate_limit:{user_id}"
    current = redis_client.get(key)

    if current is None:
        redis_client.setex(key, 60, 1)  # 60 sec TTL
        return False

    return int(current) >= 100  # Limit per product requirements doc
```

**Explains:** WHY Redis, WHY these limits, WHERE requirements came from.

### 2. Algorithms and Complex Logic

✅ **WHY this algorithm:**
```python
def find_user(users, email):
    # Binary search requires sorted array. We sort by email on load
    # to enable O(log n) lookups. Worth the upfront sort cost because
    # lookups happen 100x more frequently than updates.
    return binary_search(users, email)
```

**Explains:** WHY binary search, WHY pre-sorted, trade-off reasoning.

### 3. Magic Numbers and Constants

✅ **WHY these values:**
```python
MAX_RETRIES = 3  # Testing showed 3 retries handles 99.9% of transient failures
TIMEOUT_MS = 5000  # API SLA guarantees < 5sec response time
BATCH_SIZE = 100  # Larger batches caused memory issues in prod (incident #1234)
```

**Explains:** WHERE values came from (testing, SLA, incident).

### 4. Workarounds and Gotchas

✅ **WHY unusual code:**
```python
# WORKAROUND: Library bug #456 - must call reset() twice
# Fixed in v2.0 but we're on v1.8
client.reset()
client.reset()
```

**Warns future maintainer:** Unusual code has reason, link to issue.

## What NOT to Comment

### Don't Comment Obvious Code

❌ **Restates the code:**
```python
# Set user name to "John"
user.name = "John"

# Loop through items
for item in items:
    # Process the item
    process(item)
```

✅ **Let code speak:**
```python
user.name = "John"

for item in items:
    process(item)
```

### Don't Comment Mechanics of Standard Patterns

❌ **Obvious pattern:**
```python
# Initialize search boundaries to cover entire array
left, right = 0, len(arr) - 1

# Continue searching while there's a valid range
while left <= right:
```

✅ **Comment intent only:**
```python
def binary_search(arr, target):
    # Binary search for O(log n) performance on sorted array
    left, right = 0, len(arr) - 1
    while left <= right:
        # ... implementation (standard pattern, no comments needed)
```

## The Comment Test

**For each comment, ask:**

1. **Does it explain WHY, not WHAT?**
   - WHY: "Redis for distributed limiting" ✅
   - WHAT: "Get value from Redis" ❌

2. **Would I understand without it?**
   - If yes: Delete comment
   - If no: Keep comment OR improve code clarity

3. **Does it add information beyond the code?**
   - Yes: Keep it
   - No: Delete it

## Quick Reference

| Comment This | Don't Comment This |
|--------------|---------------------|
| WHY you chose this approach | WHAT the code does |
| Non-obvious decisions | Obvious assignments |
| Magic number sources | Standard patterns |
| Algorithm trade-offs | Mechanics of loops/conditionals |
| Workarounds and gotchas | Self-evident operations |
| Business rule origins | Variable declarations |

## Real-World Impact

From baseline:
- Agents commented every line of simple price calculation (over-commenting)
- Comments restated code without adding value
- Missed opportunities to explain WHY (decisions, trade-offs)

**With this skill:** Comment intent, not mechanics.

## Integration with Other Skills

**For evergreen comments:** See @../writing-evergreen-comments/SKILL.md - no temporal context in comments

**For self-documenting code:** See @../naming-variables/SKILL.md - good names reduce need for comments
