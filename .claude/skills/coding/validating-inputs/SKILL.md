---
name: Validating Inputs
description: Check all external inputs for validity - garbage in, nothing out, never garbage out
when_to_use: Before implementing any function that receives external data. When writing functions that take parameters from users, APIs, databases, files, or other untrusted sources. When you see missing validation, no error handling, or silent failures. When implementing without thinking "what could go wrong?". When code throws TypeError, ValueError, KeyError from missing validation. When crashes or runtime errors occur. When security vulnerabilities exist (injection attacks, buffer overflow). When data corruption happens. When code fails with unexpected inputs.
version: 1.0.0
languages: all
type: technique
---

# Validating Inputs

## Overview

Professional-grade software never outputs garbage regardless of what it receives. "Garbage in, garbage out" is the mark of sloppy, insecure code.

**Core principle:** Check all data from external sources. Validate all routine parameters from untrusted sources. Decide consciously how to handle invalid data.

**Modern standard:** "Garbage in, nothing out" OR "Garbage in, error message out" OR "No garbage allowed in"

**Violating the letter of this rule is violating the spirit of defensive programming.**

## When to Use

**Always use when writing functions that receive:**
- User input (forms, command-line args, uploaded files)
- External API responses
- Database query results
- File contents
- Network data
- Configuration files
- Any data from outside your direct control

**Warning signs you need this:**
- Function assumes inputs are valid
- No validation beyond empty/null checks
- No assertions documenting assumptions
- Spec mentions constraints but code doesn't check them
- Silent failures or wrong results with bad data
- Security vulnerabilities (injection, overflow, etc.)
- Functions accept any input without question

**Don't skip when:**
- "Inputs will always be valid" (they won't)
- "Validation happens elsewhere" (defense in depth - check anyway)
- "It's just internal code" (today's internal is tomorrow's API)
- Under time pressure (validation prevents longer debugging)

## The Two-Level Defense

### Level 1: Assertions (Should NEVER Happen)

**Use for:** Conditions that indicate bugs in YOUR code

```python
def calculate_velocity(distance: float, time: float) -> float:
    # Preconditions: These should NEVER be violated if caller is correct
    assert distance >= 0, "distance cannot be negative"
    assert time > 0, "time must be positive"

    result = distance / time

    # Postcondition: Result should be reasonable
    assert result >= 0, f"velocity cannot be negative: {result}"

    return result
```

**Assertions are:**
- Executable documentation
- Compiled out in production (typically)
- For catching programmer errors during development
- Should fire = bug in code that needs fixing

### Level 2: Error Handling (MIGHT Happen)

**Use for:** Conditions you expect might occur in production

```python
def calculate_average_score(scores: list[float]) -> float:
    """Calculate average of test scores (must be 0-100)."""

    # Error handling: Validate external data
    if scores is None:
        raise ValueError("scores cannot be None")

    if not scores:
        raise ValueError("Cannot calculate average of empty score list")

    # Validate each score
    for i, score in enumerate(scores):
        if not isinstance(score, (int, float)):
            raise TypeError(f"Score {i} is not a number: {score}")
        if score < 0 or score > 100:
            raise ValueError(f"Score {i} out of range [0-100]: {score}")

    result = sum(scores) / len(scores)

    # Postcondition: Verify result is valid
    assert 0 <= result <= 100, f"Calculated average out of range: {result}"

    return result
```

**Error handling:**
- Stays in production code
- Handles expected anomalies gracefully
- Validates external/untrusted data
- Should trigger = need to handle error, not fix code

## Quick Reference

| Situation | Approach | Example |
|-----------|----------|---------|
| **External data** | Validate everything | Check ranges, types, formats, lengths |
| **Routine parameters** | Check if from untrusted source | Validate or document assumptions |
| **Internal invariants** | Assert they hold | Assert postconditions, state assumptions |
| **Null/None** | Check explicitly | `if value is None: raise ValueError()` |
| **Empty collections** | Decide if valid or error | Empty list error or return default? |
| **Type mismatches** | Check with isinstance | `if not isinstance(score, (int, float))` |
| **Range violations** | Check bounds | `if score < 0 or score > 100` |
| **Invalid formats** | Use regex/validators | Email, phone, URLs |
| **Security risks** | Validate aggressively | SQL injection, buffer overflow, path traversal |

## Validation Checklist

Before implementing any function receiving external data:

**1. Identify all inputs**
- [ ] What data comes from outside my control?
- [ ] Which parameters could be bad?
- [ ] What are the data sources? (user, API, DB, file, network)

**2. Document constraints**
- [ ] What are valid ranges? (0-100, positive only, etc.)
- [ ] What are valid types? (int, float, string)
- [ ] What are valid formats? (email, phone, date)
- [ ] What are valid lengths? (string max, array min/max)
- [ ] Are nulls allowed?
- [ ] Are empties allowed?

**3. Think "what could go wrong?"**
- [ ] Wrong type passed
- [ ] Null/None passed
- [ ] Empty collection passed
- [ ] Negative where positive expected
- [ ] Out of range values
- [ ] Invalid format (malformed email, etc.)
- [ ] Security attacks (injection, overflow)

**4. Implement validation**
- [ ] Check each constraint explicitly
- [ ] Use error handling for expected problems
- [ ] Use assertions for programmer errors
- [ ] Provide clear error messages
- [ ] Document assumptions in assertions

**5. Decide error response**
- [ ] Return neutral value? (0, empty string, None)
- [ ] Raise exception with clear message?
- [ ] Log and continue?
- [ ] Substitute closest valid value?
- [ ] Shut down? (safety-critical)

## Robustness vs Correctness

**Consciously choose based on domain:**

### Correctness (Never Return Wrong Answer)

**Prefer when:**
- Safety-critical (medical, aviation, financial)
- Security-critical
- Data integrity critical
- Wrong result is worse than no result

**Strategy:** Validate aggressively, fail fast with errors

```python
def calculate_radiation_dosage(params):
    # Medical system: wrong dosage could kill patient
    # Better to refuse than to guess
    if not all_params_valid(params):
        raise ValueError("Cannot calculate dosage with invalid parameters")
    # If ANY doubt, raise error
```

### Robustness (Keep Operating)

**Prefer when:**
- Consumer applications
- Non-critical features
- User convenience matters
- Some result better than crash

**Strategy:** Substitute reasonable values, log issues, continue

```python
def get_user_theme_color(color_code):
    # UI preference: wrong color annoying but not critical
    # Better to show default than crash
    if not is_valid_color(color_code):
        logger.warning(f"Invalid color code {color_code}, using default")
        return DEFAULT_COLOR
    return color_code
```

**Make this choice explicit in your design.** Don't just fall into one approach without thinking.

## Common Input Validation Patterns

### Pattern 1: Validate Numeric Ranges

```python
def process_temperature(temp_celsius: float) -> float:
    # Range validation
    if not isinstance(temp_celsius, (int, float)):
        raise TypeError(f"Temperature must be numeric, got {type(temp_celsius)}")

    if temp_celsius < -273.15:  # Absolute zero
        raise ValueError(f"Temperature cannot be below absolute zero: {temp_celsius}")

    if temp_celsius > 1000:  # Sanity check
        raise ValueError(f"Temperature seems unrealistic: {temp_celsius}")

    return temp_celsius + 273.15  # Convert to Kelvin
```

### Pattern 2: Validate String Formats

```python
import re

def send_email(email_address: str) -> None:
    # Format validation
    if not email_address or not isinstance(email_address, str):
        raise ValueError("Email address required")

    email_address = email_address.strip()

    if not re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', email_address):
        raise ValueError(f"Invalid email format: {email_address}")

    if len(email_address) > 254:  # RFC 5321 limit
        raise ValueError("Email address too long")

    # Proceed with valid email
    ...
```

### Pattern 3: Validate Collections

```python
def process_batch(items: list) -> None:
    # Collection validation
    if items is None:
        raise ValueError("items cannot be None")

    if not isinstance(items, list):
        raise TypeError(f"items must be a list, got {type(items)}")

    if not items:
        raise ValueError("items list cannot be empty")

    if len(items) > 1000:  # Sanity check
        raise ValueError(f"Batch too large: {len(items)} items (max 1000)")

    for i, item in enumerate(items):
        if item is None:
            raise ValueError(f"Item {i} cannot be None")
        # Validate each item...
```

### Pattern 4: Validate Required Fields

```python
def create_user(data: dict) -> None:
    # Required fields validation
    required_fields = ['username', 'email', 'password']

    for field in required_fields:
        if field not in data:
            raise ValueError(f"Missing required field: {field}")

        if not data[field] or not isinstance(data[field], str):
            raise ValueError(f"Field '{field}' must be non-empty string")

        if not data[field].strip():
            raise ValueError(f"Field '{field}' cannot be whitespace only")
```

### Pattern 5: Preconditions and Postconditions

```python
def withdraw_money(account_id: str, amount: float) -> float:
    # Preconditions (assertions for internal invariants)
    assert account_id, "account_id should never be empty"
    assert amount > 0, "amount should be positive (checked by caller)"

    # Validation (error handling for external data)
    balance = get_balance(account_id)

    if balance < amount:
        raise ValueError(f"Insufficient funds: balance {balance}, requested {amount}")

    new_balance = balance - amount

    # Postcondition (assertion for internal invariant)
    assert new_balance >= 0, "Balance should never be negative"
    assert new_balance == balance - amount, "Math error in withdrawal"

    update_balance(account_id, new_balance)
    return new_balance
```

## Security Validation

**Especially check for:**

- **SQL Injection:** Validate/sanitize database inputs, use parameterized queries
- **Command Injection:** Never pass user input directly to system calls
- **Path Traversal:** Validate file paths don't contain `../`
- **Buffer Overflow:** Check string/array lengths against limits
- **Integer Overflow:** Validate arithmetic won't overflow
- **XSS/HTML Injection:** Sanitize user content before display
- **XML/JSON Injection:** Validate structure and content

**Rule:** Be especially paranoid with anything that could attack your system.

## Common Mistakes

**❌ Only checking for null/empty:**
```python
if not scores:
    return 0.0
return sum(scores) / len(scores)  # Doesn't check constraints!
```

**✅ Check ALL constraints:**
```python
if not scores:
    raise ValueError("Cannot calculate average of empty list")
for score in scores:
    if score < 0 or score > 100:
        raise ValueError(f"Score out of range: {score}")
return sum(scores) / len(scores)
```

---

**❌ Assuming types are correct:**
```python
def add(a, b):
    return a + b  # What if a or b are strings? None? Lists?
```

**✅ Validate types:**
```python
def add(a: float, b: float) -> float:
    if not isinstance(a, (int, float)) or not isinstance(b, (int, float)):
        raise TypeError(f"Arguments must be numeric: {type(a)}, {type(b)}")
    return a + b
```

---

**❌ Silent failure or wrong default:**
```python
if not scores:
    return 0.0  # Is 0.0 the right answer for empty? Or should it error?
```

**✅ Explicit decision:**
```python
if not scores:
    raise ValueError("Cannot calculate average of empty list")
    # OR if 0.0 is intentional:
    # return 0.0  # Intentionally return 0 for empty list per business rules
```

---

**❌ No error message context:**
```python
if age < 18:
    raise ValueError("Invalid age")  # Which age? What was the value?
```

**✅ Informative error messages:**
```python
if age < 18:
    raise ValueError(f"Age must be 18+, got {age}")
```

## Red Flags - STOP and Add Validation

**Before implementing:**
- Haven't thought "what could go wrong?"
- No validation code written yet
- Only checking null/empty
- Assuming inputs are valid
- "Validation happens elsewhere" (maybe, but check anyway)

**After implementing:**
- Function accepts any input without checking
- No assertions documenting assumptions
- Spec mentions constraints but code doesn't enforce them
- Could pass wrong type and function wouldn't catch it
- Security review would fail

**All of these mean: Add comprehensive validation now.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Inputs will always be valid" | They won't. Users make mistakes, APIs change, bugs happen. |
| "Validation happens elsewhere" | Defense in depth. Check at every layer. |
| "It's just internal code" | Today's internal is tomorrow's API. Validate anyway. |
| "Adds too much code" | 5 lines of validation prevents hours of debugging. |
| "Slows down the code" | Correctness > speed. Optimize later if needed. |
| "Trust the caller" | Trust but verify. Catch bugs at boundaries. |
| "Users know what they're doing" | Users make mistakes. Software should help, not crash. |
| "I'll add validation later" | Later never comes. Add it now. |

## Three Levels of Validation

### Level 1: Type Validation

Check data is the expected type:

```python
if not isinstance(value, expected_type):
    raise TypeError(f"Expected {expected_type}, got {type(value)}")
```

### Level 2: Constraint Validation

Check data meets business rules:

```python
if value < min_value or value > max_value:
    raise ValueError(f"Value {value} out of range [{min_value}, {max_value}]")
```

### Level 3: Format/Semantic Validation

Check data is semantically valid:

```python
if not re.match(email_pattern, email):
    raise ValueError(f"Invalid email format: {email}")
```

**Apply all three levels to external data.**

## Assertions vs Error Handling

### Use Assertions When:

- Documenting internal invariants
- Checking preconditions from trusted callers
- Verifying postconditions you guarantee
- Catching programmer errors (bugs in YOUR code)
- Development/debugging (typically compiled out in production)

```python
def withdraw(self, amount):
    assert self.balance >= 0, "Balance invariant violated"  # Should never happen
    assert amount > 0, "Caller should have checked amount"   # Caller's bug
```

### Use Error Handling When:

- Validating external/untrusted data
- Handling expected anomalies
- User input could be wrong
- API might return bad data
- Production code must handle gracefully

```python
def withdraw(self, amount):
    if amount <= 0:  # User might request $0 or negative
        raise ValueError(f"Withdrawal amount must be positive, got {amount}")

    if amount > self.balance:  # User might request too much
        raise ValueError(f"Insufficient funds: {amount} requested, {self.balance} available")
```

**Rule:** Assertions for bugs, error handling for anomalies.

## Validation Strategy by Source

| Data Source | Trust Level | Validation Approach |
|-------------|-------------|---------------------|
| **User input** | Untrusted | Validate everything aggressively |
| **External API** | Untrusted | Validate responses, handle failures |
| **Database** | Semi-trusted | Check for corruption, missing data |
| **Config file** | Semi-trusted | Validate format and values |
| **Internal parameters** | Trusted | Use assertions to document assumptions |
| **Your own methods** | Trusted | Assertions for preconditions |

## Common Validation Scenarios

### Validating Numeric Input

```python
# Check type, range, special values
if not isinstance(value, (int, float)):
    raise TypeError(f"Expected number, got {type(value)}")

if math.isnan(value) or math.isinf(value):
    raise ValueError(f"Value cannot be NaN or Inf: {value}")

if value < minimum or value > maximum:
    raise ValueError(f"Value {value} out of range [{minimum}, {maximum}]")
```

### Validating String Input

```python
# Check type, emptiness, length, format
if not isinstance(value, str):
    raise TypeError(f"Expected string, got {type(value)}")

value = value.strip()

if not value:
    raise ValueError("Value cannot be empty or whitespace only")

if len(value) > max_length:
    raise ValueError(f"Value too long: {len(value)} chars (max {max_length})")

if not pattern.match(value):
    raise ValueError(f"Value doesn't match required format: {value}")
```

### Validating Collections

```python
# Check type, emptiness, size, element validity
if not isinstance(items, list):
    raise TypeError(f"Expected list, got {type(items)}")

if not items:
    raise ValueError("List cannot be empty")

if len(items) > max_items:
    raise ValueError(f"Too many items: {len(items)} (max {max_items})")

for i, item in enumerate(items):
    if item is None:
        raise ValueError(f"Item {i} cannot be None")
    # Validate each element...
```

## Error Response Strategies

Choose consciously based on domain:

### 1. Return Neutral Value

**When:** Non-critical, user convenience matters

```python
def get_color_preference(color_code):
    if not is_valid_color(color_code):
        return DEFAULT_COLOR  # Neutral, harmless
    return color_code
```

### 2. Substitute Valid Value

**When:** Can safely substitute without data loss

```python
def clamp_temperature(temp):
    # Thermometer calibrated 0-100°C
    if temp < 0:
        return 0  # Closest valid value
    if temp > 100:
        return 100
    return temp
```

### 3. Raise Exception

**When:** Caller must handle the error

```python
def charge_payment(amount):
    if amount <= 0:
        raise ValueError(f"Payment amount must be positive: {amount}")
    # Process payment
```

### 4. Log and Continue

**When:** Error isn't critical, want visibility

```python
def sync_data(data):
    if not is_valid(data):
        logger.warning(f"Invalid data encountered, skipping: {data}")
        return
    # Process valid data
```

### 5. Shut Down

**When:** Safety-critical, wrong result is dangerous

```python
def control_reactor(params):
    if not params_within_safe_limits(params):
        emergency_shutdown()
        raise CriticalError("Unsafe parameters detected, reactor shut down")
```

## Verification Before Shipping

Before marking validation complete:

- [ ] Identified ALL external data sources
- [ ] Validated ALL constraints from spec
- [ ] Used assertions for internal invariants
- [ ] Used error handling for external anomalies
- [ ] Provided clear, informative error messages
- [ ] Consciously chose: robustness vs correctness
- [ ] Tested with invalid inputs (not just valid ones)
- [ ] Security-reviewed for injection/overflow/attacks

## Real-World Impact

From Code Complete and baseline testing:

**Baseline test results:**
- Agent only checked empty list (most basic edge case)
- Ignored spec constraint (scores must be 0-100)
- No type checking, no assertions, no comprehensive validation
- Grade: D- for defensive programming

**With validation:**
- Catches bad data at boundary (not deep in call stack)
- Clear error messages aid debugging
- Assertions catch programmer errors early
- Production code is robust and secure

**Industry impact:**
- Security vulnerabilities often stem from missing input validation
- Defensive programming prevents "impossible" errors
- Validating early is cheaper than debugging later

## Integration with Other Skills

**For multi-layer validation:** See @../../debugging/defense-in-depth/SKILL.md for validating at every layer data passes through

**For systematic debugging:** If validation fails in production, see @../../debugging/systematic-debugging/SKILL.md for root cause analysis
