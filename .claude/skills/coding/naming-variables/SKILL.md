---
name: Naming Variables
description: Choose names that fully and accurately describe what the variable represents
when_to_use: When naming any variable, function, class, or parameter. When struggling to name something (warning sign of design problem). When seeing cryptic names like x, temp, data. When abbreviating names. When code is hard to understand.
version: 1.0.0
languages: all
---

# Naming Variables

## Overview

The most important consideration in naming a variable is that the name fully and accurately describes the entity the variable represents.

**Core principle:** A variable and its name are essentially the same thing. The goodness or badness of a variable is largely determined by its name.

**Name quality = Design quality.** If you struggle to name something well, that's a warning sign about the design.

## When to Use

**Always use when:**
- Naming any variable, function, class, parameter, constant
- Reviewing code with unclear names
- Struggling to understand what a variable does

**Warning signs you need better names:**
- Variables named `x`, `x1`, `x2`, `temp`, `data`, `info`, `val`
- Can't remember what a variable does
- Need to search back to find variable's purpose
- Abbreviations that aren't obvious
- Names that could mean multiple things
- Struggling to name something (indicates design problem)

## Naming Principles

### 1. Describe What, Not How

**Problem-oriented** (what it represents) not **solution-oriented** (how it's implemented):

✅ **Good:** `employeeData`, `printerReady`, `totalRevenue`
❌ **Bad:** `inputRec`, `bitFlag`, `calcVal`

The bad names describe computing concepts (input, record, bit, calculation). Good names describe the problem domain (employee, printer, revenue).

### 2. Use Optimal Name Length

**Optimal: 10-16 characters average**
- Too short: doesn't convey meaning
- Too long: hard to type, obscures structure

| Too Long | Too Short | Just Right |
|----------|-----------|------------|
| `numberOfPeopleOnTheUsOlympicTeam` | `n`, `np`, `ntm` | `numTeamMembers`, `teamMemberCount` |
| `numberOfSeatsInTheStadium` | `n`, `ns`, `nsisd` | `numSeatsInStadium`, `seatCount` |
| `maximumNumberOfPointsInModernOlympics` | `m`, `mp`, `max` | `teamPointsMax`, `pointsRecord` |

**Exception:** Short names OK for very limited scope (loop index `i` in 3-line loop)

### 3. Scope Affects Name Length

- **Long scope (class, global):** Longer, more descriptive names
- **Short scope (loop variable, local):** Shorter acceptable
- **Very short scope (5-line loop):** `i`, `j` acceptable

Short name says: "I'm a scratch value with limited scope, don't look for me elsewhere"

### 4. State What Variable Represents

Effective technique: state in words what the variable represents. Often that statement IS the best name.

**Example:**
- "Running total of checks written to date" → `runningTotal` or `checkTotal`
- "Velocity of a bullet train" → `velocity`, `trainVelocity`, `velocityInMph`
- "Current date" → `currentDate`, `todaysDate`

### 5. Computed-Value Qualifiers at End

Put qualifiers like `Total`, `Sum`, `Average`, `Max`, `Min`, `Count` at the END:

✅ **Good:** `revenueTotal`, `expenseAverage`, `pointsMax`, `customerCount`
❌ **Bad:** `totalRevenue` mixed with `revenueTotal` (inconsistent)

**Why:**
- Most significant part (revenue, expense) at front, read first
- Symmetry: `revenueTotal`, `revenueAverage`, `revenueMax`
- Prevents confusion (`totalRevenue` vs `revenueTotal` - pick one convention)

**Exception:** `Num` is ambiguous
- At start = total: `numCustomers` (count of all customers)
- At end = index: `customerNum` (specific customer number)
- **Better:** Use `Count` for total, `Index` for specific: `customerCount`, `customerIndex`

### 6. Use Obvious Words

Don't be clever. Use the ordinary, obvious words:

✅ `currentDate`, `employeeName`, `accountBalance`
❌ `cd`, `empNm`, `acctBal`

Programmers sometimes overlook using ordinary words, which is often the easiest solution.

### 7. Be Specific, Not Generic

Names that are too general can be used for anything = not informative:

❌ **Bad:** `x`, `temp`, `data`, `info`, `value`, `variable`
✅ **Good:** `discriminant`, `oldRoot`, `errorMessage`, `customerInfo`, `totalRevenue`

Generic names acceptable ONLY for very limited scope.

## Naming Conventions

Standard patterns for consistency and clarity:

### Computed-Value Qualifiers

Place qualifiers at the **end** of the name:

✅ **Good:** `userCount`, `revenueTotal`, `temperatureMax`, `priceAverage`, `itemsMin`
❌ **Bad:** `totalRevenue` mixed with `revenueTotal` (inconsistent)

**Why at end:**
- Most significant part (user, revenue, temperature) read first
- Symmetry: `revenueTotal`, `revenueAverage`, `revenueMax`
- Prevents confusion between `totalRevenue` and `revenueTotal`

**Common qualifiers:** `Total`, `Sum`, `Average`, `Max`, `Min`, `Count`, `Index`

### Collections (Arrays, Lists, Sets)

Use **plural** names:

✅ **Good:** `users`, `activeCustomers`, `recentOrders`, `errorMessages`
❌ **Bad:** `userList`, `customerArray`, `orderSet` (exposes implementation)

**Exception:** When type disambiguation helps: `userMap`, `userSet` (if you have both in same scope)

### Booleans

Use question form (prefix with `is`, `has`, `can`, `should`):

✅ **Good:** `isValid`, `hasPermission`, `canEdit`, `shouldRetry`, `wasProcessed`
❌ **Bad:** `valid`, `permission`, `edit`, `retry` (not obviously boolean)

**Avoid negative booleans:** `isNotValid` is confusing. Use `isValid` and check `!isValid`.

### Constants

Use **SCREAMING_SNAKE_CASE** for truly constant values:

✅ **Good:** `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_MS`, `API_BASE_URL`

**Modern alternative:** `const` with regular camelCase (TypeScript, modern JavaScript):

✅ **Also good:** `const maxRetryCount = 3`

Pick one convention per project, stay consistent.

### Index vs Count

**Distinguish clearly:**

- **Count/Total** = how many total: `userCount`, `itemTotal`
- **Index** = which specific one: `userIndex`, `currentItem`

❌ **Confusing:** `userNum` (is it count or index?)
✅ **Clear:** `userCount` (total), `userIndex` (specific)

### Temporary Variables

**Minimize or make semantic:**

❌ **Bad:** `temp`, `tmp`, `t`
✅ **Good:** `oldValue`, `swapBuffer`, `previousState`

If truly temporary and tiny scope (2-3 lines), short is OK. Otherwise, give it semantic meaning.

## Language-Specific Adaptations

### Python (snake_case)
```python
user_count = 0          # count
current_user_index = 0  # index
is_valid = True         # boolean
active_users = []       # collection
MAX_RETRY_COUNT = 3     # constant
```

### JavaScript/TypeScript (camelCase)
```typescript
const userCount = 0;          // count
let currentUserIndex = 0;     // index
const isValid = true;         // boolean
const activeUsers = [];       // collection
const MAX_RETRY_COUNT = 3;    // constant
```

### Go (mixedCase/camelCase)
```go
userCount := 0           // count
currentUserIndex := 0    // index
isValid := true         // boolean
activeUsers := []User{}  // collection
const MaxRetryCount = 3  // exported constant
```

**Principle applies across languages:** Name describes what it represents, adapt casing to language conventions.

## Common Opposites

Use opposites precisely for consistency:

| Opposite Pairs |
|----------------|
| `begin` / `end` |
| `first` / `last` |
| `locked` / `unlocked` |
| `min` / `max` |
| `next` / `previous` |
| `old` / `new` |
| `opened` / `closed` |
| `source` / `target` |
| `source` / `destination` |
| `start` / `stop` |
| `up` / `down` |
| `get` / `set` |
| `add` / `remove` |
| `insert` / `delete` |
| `show` / `hide` |
| `create` / `destroy` |
| `increment` / `decrement` |

Departing from common opposites (like `begin`/`finish` instead of `begin`/`end`) is confusing.

## Variables to Avoid

**Never use unless you have explicit, documented reason:**

❌ `x`, `x1`, `x2` - Always bad (represents unknown quantity)
❌ `temp` - What kind of temporary value?
❌ `data` - What data?
❌ `val`, `value` - What value?
❌ `foo`, `bar`, `baz` - Placeholder nonsense
❌ Single letters except `i`, `j`, `k` for very short loops
❌ Misspellings or weird abbreviations
❌ Names with numbers: `file1`, `file2` (use array instead)
❌ Names differing by only one character: `acctNum` vs `acctNo`

## One Purpose Per Variable

**Never reuse a variable for multiple purposes:**

❌ **Bad:**
```python
# temp used for two unrelated purposes
temp = sqrt(b*b - 4*a*c)
root[0] = (-b + temp) / (2 * a)
...
temp = root[0]  # Now reused for swapping
root[0] = root[1]
root[1] = temp
```

✅ **Good:**
```python
discriminant = sqrt(b*b - 4*a*c)
root[0] = (-b + discriminant) / (2 * a)
...
old_root = root[0]
root[0] = root[1]
root[1] = old_root
```

**Avoid hidden meanings:**
- `pageCount` = number of pages, UNLESS it equals -1, then it means error occurred ❌
- `customerId` = customer number, UNLESS > 500000, then subtract 500000 for delinquent account ❌

Use separate variables. Don't overload meaning.

## Naming as a Diagnostic Tool

**If naming is hard = design is unclear:**

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| Vague name seems OK | Routine does too many things | Break into smaller routines |
| Multiple equally-vague names | Unclear purpose | Clarify requirements |
| Name is long and complicated | Routine is too complex | Simplify design |
| Can't decide between 2 names | Routine has dual purpose | Split into two routines |
| Name keeps changing | Design keeps changing | Stabilize design first |

**Don't just accept a bad name. Treat it as a red flag about code quality.**

## Quick Naming Checklist

Before accepting a name:
- [ ] Describes WHAT variable represents fully and accurately?
- [ ] Uses problem domain language (not computer terms)?
- [ ] 10-16 characters for anything beyond local scope?
- [ ] Obvious words used (not clever or abbreviated)?
- [ ] Specific enough (not generic like `temp`, `data`)?
- [ ] One purpose only (no hybrid meanings)?
- [ ] Computed qualifiers at end (`Total`, `Max`, `Count`)?
- [ ] If short name, is scope truly tiny (< 10 lines)?

**If any answer is no: improve the name.**

## Real-World Impact

From Code Complete research:
- Programs with names averaging 10-16 characters had minimized debugging effort
- Study found 30%+ improvement in comprehension with well-named abstractions
- Names like `x1`, `x2` prevent understanding relationships between variables
- Vague names correlate with design problems

**Key insight:** "You can't give a variable a name the way you give a dog a name—because it's cute or it has a good sound. A variable and a variable's name are essentially the same thing."

## Example Transformation

❌ **Before (Bad Names):**
```python
x = x - xx
xxx = fido + sales_tax(fido)
x = x + late_fee(x1, x) + xxx
x = x + interest(x1, x)
```

What does this do? What is `x`, `xx`, `xxx`, `fido`, `x1`?

✅ **After (Good Names):**
```python
balance = balance - last_payment
monthly_total = new_purchases + sales_tax(new_purchases)
balance = balance + late_fee(customer_id, balance) + monthly_total
balance = balance + interest(customer_id, balance)
```

Now it's obvious: computing customer bill from balance and new purchases.

**Same code, different names, completely different understandability.**

## Integration with Other Skills

**For domain-focused naming:** See @../naming-by-domain/SKILL.md for architectural naming principles (avoid temporal context like "New"/"Improved", avoid implementation details like "ZodValidator", avoid unnecessary pattern names)

**For comment guidelines:** See @../writing-evergreen-comments/SKILL.md for keeping comments evergreen
