---
name: Keeping Routines Focused
description: Each routine does one thing and does it well - extract when routines have multiple responsibilities
when_to_use: When writing any function or method. When routine does multiple things. When routine description has "and" in it. When routine is hard to name. When routine is longer than 200 lines. When parameter list exceeds 7 parameters. When refactoring complex code. When god function exists. When function does too much. When tests are hard to write for a function. When mixed abstraction levels in one routine. When code review flags "too complex" or "does too many things". When cohesion is weak. When violating single responsibility principle. When function has many local variables.
version: 1.0.0
languages: all
type: technique
---

# Keeping Routines Focused

## Overview

A routine should do ONE thing and do it well. This is called functional cohesion - the strongest, best kind of cohesion.

**Core principle:** If a routine's description contains "and", it's doing too many things. Extract into focused routines.

**Goal:** Improve intellectual manageability. The more focused a routine, the easier to understand, test, modify, and reuse.

## When to Use

**Proactively (writing new code):**
- Designing new functions/methods
- Writing routine specifications
- Naming routines (if name is vague or has "and", too many responsibilities)

**Reactively (improving existing code):**
- Reviewing code with long routines
- Refactoring when routine does multiple things
- When routine is hard to understand or test
- When routine keeps growing with each modification

**Warning signs routine needs focus:**
- Description has "and" in it
- Routine name is vague or long
- Routine is hard to name clearly
- Routine is > 200 lines (strong signal)
- Parameter list > 7 parameters
- Many local variables (> 10)
- Multiple levels of abstraction mixed
- Does validation AND calculation AND side-effects
- Hard to write test (does too much to test atomically)

## What is "One Thing"?

**One thing means one level of abstraction:**

✅ **Does one thing:**
```python
def calculate_total_price(items, tax_rate):
    """Calculate total price of items including tax."""
    subtotal = sum(item.price * item.quantity for item in items)
    tax = subtotal * tax_rate
    return subtotal + tax
```

Single purpose: price calculation. All statements at same abstraction level (arithmetic).

---

❌ **Does multiple things:**
```python
def handle_order(order_data, user_id):
    """
    Process order:
    - Validate order data
    - Calculate total with tax
    - Apply discount codes
    - Check inventory
    - Create order record
    - Send confirmation email
    - Update user history
    - Return confirmation
    """
    validated = validate_order_data(order_data, user_id)  # Thing 1
    subtotal = calculate_subtotal(validated["items"])     # Thing 2
    discount = apply_discount(subtotal, validated.get("discount_code"))  # Thing 3
    tax = calculate_tax(subtotal - discount, validated["tax_rate"])      # Thing 4
    total = subtotal - discount + tax                      # Thing 5
    check_inventory(validated["items"])                    # Thing 6
    order_record = create_order_record(...)                # Thing 7
    send_confirmation_email(...)                           # Thing 8
    update_user_history(user_id, order_record["order_id"]) # Thing 9
    return {...}  # Thing 10
```

Description has 8 "and"s. Does 10 different things. Violates single responsibility.

## How to Extract Routines

### Technique 1: Extract by Responsibility

Group related statements, extract into focused routine:

**Before (orchestrator does everything):**
```python
def handle_order(order_data, user_id):
    # Validation (lines 1-10)
    validated = validate_order_data(order_data, user_id)

    # Pricing (lines 11-15)
    subtotal = calculate_subtotal(validated["items"])
    discount = apply_discount(subtotal, validated.get("discount_code"))
    tax = calculate_tax(subtotal - discount, validated["tax_rate"])
    total = subtotal - discount + tax

    # Inventory (lines 16-20)
    check_inventory(validated["items"])

    # Persistence (lines 21-30)
    order_record = create_order_record(...)

    # Notifications (lines 31-35)
    send_confirmation_email(...)
    update_user_history(user_id, order_record["order_id"])

    return {...}
```

**After (each phase is focused routine):**
```python
def handle_order(order_data, user_id):
    """Single responsibility: Orchestrate order processing."""
    validated_order = validate_order_request(order_data, user_id)
    pricing = calculate_order_pricing(validated_order)
    verify_inventory_available(validated_order)
    order = create_and_save_order(validated_order, pricing, user_id)
    send_order_notifications(order)
    return create_confirmation_response(order, pricing)

def validate_order_request(order_data, user_id):
    """Single responsibility: Validate order data."""
    # Just validation

def calculate_order_pricing(validated_order):
    """Single responsibility: Calculate prices."""
    # Just pricing math

def verify_inventory_available(validated_order):
    """Single responsibility: Check inventory."""
    # Just inventory check

def create_and_save_order(validated_order, pricing, user_id):
    """Single responsibility: Persist order."""
    # Just database operations

def send_order_notifications(order):
    """Single responsibility: Send notifications."""
    # Just email/notifications
```

**Each routine now has single, clear purpose.**

### Technique 2: Extract Levels of Abstraction

If routine mixes high and low-level operations, extract low-level:

❌ **Mixed abstraction levels:**
```python
def process_report():
    # High level
    data = fetch_data()

    # LOW level detail
    for i in range(len(data)):
        if data[i] is not None and data[i] > 0:
            normalized = (data[i] - min_val) / (max_val - min_val)
            data[i] = normalized

    # High level
    generate_output(data)
```

✅ **Consistent abstraction:**
```python
def process_report():
    # All high level
    data = fetch_data()
    normalized_data = normalize_values(data)  # Low-level extracted
    generate_output(normalized_data)

def normalize_values(data):
    # Low-level details isolated here
    result = []
    for value in data:
        if value is not None and value > 0:
            normalized = (value - min_val) / (max_val - min_val)
            result.append(normalized)
    return result
```

### Technique 3: Extract Complex Conditions

If conditional logic is complex, extract to well-named boolean function:

❌ **Complex inline condition:**
```python
if (user.age >= 18 and user.has_account and
    user.account_balance > minimum and not user.is_suspended and
    user.verified_email):
    allow_purchase()
```

✅ **Extracted condition:**
```python
if is_eligible_for_purchase(user):
    allow_purchase()

def is_eligible_for_purchase(user):
    """Single responsibility: Determine purchase eligibility."""
    return (user.age >= 18 and
            user.has_account and
            user.account_balance > minimum and
            not user.is_suspended and
            user.verified_email)
```

**Benefits:** Name explains WHAT checking, function explains HOW.

## Quick Reference

| Sign Routine Needs Focus | Extraction Technique |
|--------------------------|----------------------|
| Description has "and" | Extract each responsibility |
| Routine > 200 lines | Extract logical sections |
| Parameters > 7 | Group related params, extract |
| Hard to name | Clarify purpose, split if multiple |
| Hard to test | Extract testable pieces |
| Mixed abstraction levels | Extract low-level details |
| Deep nesting | Extract nested logic |
| Long parameter list | Extract to class or group params |
| Does A, B, C, D | Extract B, C, D into focused routines |

## Functional Cohesion

**The gold standard:** Routine does one thing and only that thing.

### Levels of Cohesion (Worst to Best)

1. **Coincidental** - Unrelated things grouped together (avoid)
2. **Logical** - Related things but different operations (weak)
3. **Temporal** - Things done at same time (weak)
4. **Procedural** - Things done in sequence (medium)
5. **Communicational** - Work on same data (medium)
6. **Sequential** - Output of one is input to next (good)
7. **Functional** - Do ONE thing completely (best)

**Always aim for functional cohesion.**

### Examples of Cohesion Types

**❌ Coincidental (worst):**
```python
def miscellaneous_functions():
    initialize_printer()
    calculate_payroll()
    sort_personnel_records()
    # Unrelated things in one routine - terrible
```

**⚠️ Temporal (weak):**
```python
def startup():
    initialize_database()
    initialize_ui()
    initialize_logging()
    # Related by WHEN (startup), not by WHAT
```

**✅ Functional (best):**
```python
def calculate_employee_pay(employee, hours_worked):
    # Does ONE thing: calculate pay
    hourly_rate = employee.rate
    gross_pay = hourly_rate * hours_worked
    deductions = calculate_deductions(gross_pay)
    return gross_pay - deductions
```

## Naming as a Diagnostic

**Routine name reveals focus:**

| Name | Focus Assessment |
|------|------------------|
| `calculateTotal()` | ✅ Focused - one clear purpose |
| `processData()` | ❌ Vague - what processing? |
| `getUserAndValidate()` | ❌ Two things ("and" in name) |
| `initializeSystemData()` | ⚠️ Might be multiple things |
| `handleUserRegistrationAndWelcomeEmail()` | ❌ Obviously two things |

**If you struggle to name a routine clearly, it probably does too many things.**

Extract until naming is easy.

## Parameter Count Guideline

**Research shows:** Routines with > 7 parameters correlate with higher error rates.

**Why?** Many parameters suggest routine is doing too much.

❌ **Too many parameters:**
```python
def create_order(user_id, items, shipping_addr, billing_addr,
                 discount_code, tax_rate, payment_method, notes):
    # 8 parameters - probably doing too much
```

✅ **Group related parameters:**
```python
def create_order(user_id, order_details):
    # 2 parameters - order_details is an object containing the data
```

✅ **Or extract responsibilities:**
```python
def create_order(validated_order, calculated_pricing):
    # Validation and pricing are separate responsibilities
    # This routine just creates the order record
```

## Length Guidelines

**No hard limit, but:**
- Most routines: < 50 lines
- Review if > 100 lines
- Strong signal to extract if > 200 lines

**Exception:** Generated code, complex state machines, extensive error handling

**Question to ask:** Can I extract logical sections without making code worse?

## When to Extract

### Extract When:

1. **Multiple responsibilities** - Routine does A and B and C
2. **Mixed abstraction levels** - High-level calls mixed with low-level details
3. **Complex section** - One part is complex, rest is simple (extract complex part)
4. **Duplicate logic** - Same code appears in multiple places
5. **Hard to test** - Doing too much to test atomically
6. **Poor naming** - Can't name it clearly (probably unfocused)
7. **Long routine** - Natural extraction points exist

### Don't Extract When:

1. **Simpler inline** - Extraction adds more complexity than it removes
2. **Used once** - No duplication, no complexity reduction
3. **No natural boundary** - Arbitrary split would make code harder to understand

**Default:** When in doubt, extract. Extraction rarely makes code worse.

## Extraction Patterns

### Pattern 1: Extract Complex Calculation

```python
# ✅ Extract complex logic
def calculate_mortgage_payment(principal, annual_rate, years):
    monthly_rate = convert_to_monthly_rate(annual_rate)
    num_payments = years * 12
    return calculate_monthly_payment(principal, monthly_rate, num_payments)

def convert_to_monthly_rate(annual_rate):
    return annual_rate / 12 / 100

def calculate_monthly_payment(principal, monthly_rate, num_payments):
    return principal * (monthly_rate * (1 + monthly_rate)**num_payments) / \
           ((1 + monthly_rate)**num_payments - 1)
```

### Pattern 2: Extract Validation

```python
# ✅ Extract validation to focused routine
def process_payment(payment_data):
    validate_payment_data(payment_data)  # Extracted
    return execute_payment_transaction(payment_data)

def validate_payment_data(data):
    """Single responsibility: validation."""
    # All validation logic here
```

### Pattern 3: Extract by Abstraction Level

```python
# ✅ High-level routine calls lower-level focused routines
def generate_report():
    # High-level orchestration
    data = collect_report_data()
    analysis = analyze_data(data)
    formatted_report = format_report_output(analysis)
    save_report(formatted_report)
    return formatted_report
```

## Common Mistakes

**❌ God function (does everything):**
```python
def handle_user_request():
    # Validation
    # Authentication
    # Authorization
    # Business logic
    # Database operations
    # Logging
    # Email sending
    # Response formatting
    # 300 lines doing 8 different things
```

**✅ Focused orchestrator:**
```python
def handle_user_request(request):
    """Single responsibility: Orchestrate request handling."""
    user = authenticate_user(request)
    authorize_action(user, request.action)
    result = execute_business_logic(request, user)
    save_to_database(result)
    send_notifications(user, result)
    return format_response(result)
```

---

**❌ Mixed abstraction levels:**
```python
def process_order(order):
    validate_order(order)  # High level

    # Low level details mixed in
    for item in order.items:
        db.execute("UPDATE inventory SET quantity = quantity - ? WHERE id = ?",
                   (item.quantity, item.product_id))

    send_confirmation(order)  # High level
```

✅ **Consistent abstraction:**
```python
def process_order(order):
    """High-level orchestration."""
    validate_order(order)
    update_inventory(order.items)  # Low-level extracted
    send_confirmation(order)

def update_inventory(items):
    """Low-level: Update database."""
    for item in items:
        db.execute("UPDATE inventory SET quantity = quantity - ? WHERE id = ?",
                   (item.quantity, item.product_id))
```

---

**❌ "Utility" routine (does miscellaneous things):**
```python
def utils():
    # Initializes printer
    # Calculates payroll
    # Sorts records
    # Unrelated things - coincidental cohesion (worst)
```

✅ **Focused routines:**
```python
def initialize_printer(): ...
def calculate_payroll(): ...
def sort_personnel_records(): ...
```

## The "And" Test

**Listen to your description of the routine:**

❌ "This routine validates the input AND calculates the result AND sends email"
→ Three responsibilities. Extract 2 of them.

❌ "This gets user data AND formats it for display"
→ Two responsibilities (retrieval and formatting). Extract formatting.

✅ "This calculates the shipping cost based on weight and destination"
→ One responsibility (calculation). The "and" lists parameters, not responsibilities.

**If description has "and" connecting actions → routine does too many things.**

## Quick Decision Tree

```
Need to write/review a routine
  ↓
Does it do ONE thing?
  ├─ YES → Good, keep it focused
  └─ NO → Does description have "and"?
      ├─ YES → Extract responsibilities
      └─ Mixed abstraction levels?
          ├─ YES → Extract low-level details
          └─ > 200 lines?
              ├─ YES → Find natural boundaries, extract
              └─ > 7 parameters?
                  ├─ YES → Group params or extract
                  └─ Hard to name?
                      ├─ YES → Clarify purpose, maybe split
                      └─ Keep as-is, it's focused
```

## Extraction Example

**Original (unfocused):**
```python
def handle_order(order_data, user_id):
    # Validate (responsibility 1)
    if not order_data.get("items"):
        raise ValueError("No items")
    if not user_id:
        raise ValueError("No user")

    # Calculate pricing (responsibility 2)
    subtotal = sum(item["price"] * item["qty"] for item in order_data["items"])
    tax = subtotal * 0.08
    total = subtotal + tax

    # Check inventory (responsibility 3)
    for item in order_data["items"]:
        if inventory[item["id"]] < item["qty"]:
            raise InventoryError()

    # Create record (responsibility 4)
    order_id = f"ORD-{datetime.now().isoformat()}"
    order = {"id": order_id, "user_id": user_id, "total": total}
    save_order(order)

    # Send email (responsibility 5)
    send_email(user_id, f"Order {order_id} confirmed")

    return order
```

**Extracted (focused routines):**
```python
def handle_order(order_data, user_id):
    """Single responsibility: Orchestrate order flow."""
    validate_order_request(order_data, user_id)
    pricing = calculate_pricing(order_data)
    verify_inventory(order_data)
    order = create_order(order_data, pricing, user_id)
    notify_user(order, user_id)
    return order

def validate_order_request(order_data, user_id):
    """Single responsibility: Validation."""
    if not order_data.get("items"):
        raise ValueError("No items")
    if not user_id:
        raise ValueError("No user")

def calculate_pricing(order_data):
    """Single responsibility: Pricing."""
    subtotal = sum(item["price"] * item["qty"] for item in order_data["items"])
    tax = subtotal * 0.08
    return {"subtotal": subtotal, "tax": tax, "total": subtotal + tax}

def verify_inventory(order_data):
    """Single responsibility: Inventory check."""
    for item in order_data["items"]:
        if inventory[item["id"]] < item["qty"]:
            raise InventoryError(f"Insufficient inventory for {item['id']}")

def create_order(order_data, pricing, user_id):
    """Single responsibility: Order creation."""
    order_id = f"ORD-{datetime.now().isoformat()}"
    order = {"id": order_id, "user_id": user_id, "total": pricing["total"]}
    save_order(order)
    return order

def notify_user(order, user_id):
    """Single responsibility: Notification."""
    send_email(user_id, f"Order {order['id']} confirmed")
```

**Benefits:**
- Each routine has single, testable responsibility
- Can modify pricing without touching validation
- Can reuse validate_order_request elsewhere
- Easy to understand each piece in isolation
- Clear names describe exactly what each does

## Benefits of Focused Routines

### 1. Easier to Understand

Small, focused routines are easier to comprehend:
- Can understand without seeing rest of system
- Name tells you what it does
- Implementation is short enough to hold in mind

### 2. Easier to Test

```python
# ✅ Easy to test focused routine
def calculate_tax(amount, rate):
    return amount * rate

# Test with various inputs, done

# ❌ Hard to test unfocused routine
def handle_order(...):
    # Does 8 things - need to test all 8 in combination
    # Need mocks for email, database, inventory, etc.
```

### 3. Easier to Modify

Focused routines have clear boundaries:
- Change pricing logic → modify calculate_pricing only
- Change validation → modify validate_order_request only
- Changes don't ripple unexpectedly

### 4. Easier to Reuse

```python
# ✅ Can reuse focused routines
def handle_order(...):
    validate_order_request(...)  # Reusable

def handle_return(...):
    validate_order_request(...)  # Same validation, different context
```

### 5. Reduces Complexity

Breaking into focused pieces makes each piece simpler:
- One routine: 200 lines, complex
- Four routines: 50 lines each, simple

**Mental load:** Understand 50 lines vs understand 200 lines.

## When Routine is Appropriately Long

**Some routines are naturally longer:**

1. **Extensive but straightforward validation** - Many simple checks in sequence
2. **State machines** - Many states and transitions
3. **Generated code** - Auto-generated switch statements
4. **Linear algorithms** - Many sequential steps with no natural boundaries

**Question:** Are there natural extraction points that would improve clarity?

**If no → keep as-is. If yes → extract.**

## Verification Checklist

For each routine, check:

- [ ] Does ONE thing (functional cohesion)?
- [ ] Description has no "and" connecting different actions?
- [ ] Name clearly describes the one thing it does?
- [ ] All statements at consistent abstraction level?
- [ ] Parameters < 7 (or grouped into object)?
- [ ] Length natural for its purpose (not artificially inflated)?
- [ ] Easy to write test case?
- [ ] Can understand without seeing rest of system?

**If any "no" → consider extracting.**

## Real-World Impact

From Code Complete:
- Functional cohesion is strongest, most maintainable
- Routines doing one thing are easiest to understand
- Most routines should be simple enough to name clearly
- Parameter count > 7 correlates with higher error rates

From baseline testing:
- Agent extracted helper functions (good instinct!)
- BUT orchestrator still did 8-10 things
- Each helper was focused, but main routine wasn't
- Grade: C (good instinct, incomplete application)

**With this skill:** Both helpers AND orchestrators stay focused.

## Integration with Other Skills

**For extracting during refactoring:** See @../designing-before-coding/SKILL.md - sometimes one pseudocode line explodes to many code lines, indicating need to extract

**For complexity reduction:** See @../../architecture/reducing-complexity/SKILL.md - focused routines reduce mental juggling required
