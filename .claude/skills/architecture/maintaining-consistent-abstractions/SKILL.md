---
name: Maintaining Consistent Abstractions
description: Class interfaces present one cohesive abstraction - don't mix domain logic with serialization, persistence, or unrelated concerns
when_to_use: When designing any class interface. When class has mixed responsibilities. When class groups unrelated functions. When domain object knows about JSON/XML/database. When class description has multiple purposes. When interface mixes high and low level operations. When temporal cohesion exists (grouped by when, not what). When reviewing classes for abstraction quality. When creating grab-bag utility classes. When mixing serialization with domain logic. When persistence mixed with business logic. When class difficult to name clearly. When cohesion is weak. When single responsibility violated at class level. When Abstract Data Type unclear.
version: 1.0.0
languages: all
type: pattern
---

# Maintaining Consistent Abstractions

## Overview

A class interface should present ONE cohesive abstraction. All methods should work toward a consistent purpose at a consistent level.

**Core principle:** Each class implements one Abstract Data Type (ADT). If you can't identify what ADT the class implements, it has poor abstraction.

**Goal:** Anyone using the class should see a clear, consistent set of related operations, not a miscellaneous grab-bag.

## When to Use

**Apply when designing any class:**
- New class design
- Reviewing existing classes
- Refactoring
- API design

**Warning signs of poor abstraction:**
- Class groups unrelated functions
- Methods at different abstraction levels (high-level + low-level mixed)
- Domain object with serialization methods (to_json, to_xml)
- Business logic mixed with persistence (SQL in domain class)
- Temporal cohesion (things done at same time, not related by purpose)
- Can't clearly state what abstraction the class represents
- Class description has "and" connecting unrelated purposes

## Abstraction Anti-Patterns from Baseline Testing

### Anti-Pattern 1: Domain + Serialization Mixed

**Baseline violation:**
```python
class Employee:
    def calculate_annual_salary(self):  # ✅ Domain operation
        return self.salary * 12

    def update_department(self, dept):  # ✅ Domain operation
        self.department = dept

    def to_json(self):  # ❌ Serialization detail
        return json.dumps({...})

    def get_details(self):  # ✅ Domain operation
        return {...}
```

**Problem:** Employee is a domain concept. JSON is a serialization format. Mixing these means:
- Employee must know about JSON, XML, Protobuf, etc.
- Changes to serialization format change Employee class
- Can't serialize same employee different ways

✅ **Separate concerns:**
```python
class Employee:
    """Domain: Employee business logic only."""
    def __init__(self, name, employee_id, department, salary):
        self.name = name
        self.employee_id = employee_id
        self.department = department
        self.salary = salary

    def calculate_annual_salary(self):  # Domain
        return self.salary * 12

    def update_department(self, dept):  # Domain
        self.department = dept

# Separate serializer
class EmployeeSerializer:
    """Concern: Serialization formats."""
    @staticmethod
    def to_json(employee: Employee) -> str:
        return json.dumps({
            'name': employee.name,
            'id': employee.employee_id,
            ...
        })

    @staticmethod
    def to_xml(employee: Employee) -> str:
        # Can add XML without touching Employee
        pass
```

**Now:** Employee knows nothing about formats. Add CSV/XML/Protobuf without changing Employee.

### Anti-Pattern 2: Miscellaneous Grab-Bag (Temporal Cohesion)

**Baseline violation:**
```python
class Program:
    """Initialize application components."""
    def _init_database(self):  # Database concern
        pass

    def _setup_web_server(self):  # Web concern
        pass

    def _start_background_jobs(self):  # Jobs concern
        pass

    def _init_command_stack(self):  # Command concern
        pass

    def _init_report_formatter(self):  # Reports concern
        pass
```

**Problem:** These are unrelated functions grouped because they happen at startup (temporal cohesion). The class has no consistent abstraction - it's a miscellaneous collection.

**Code Complete specifically calls this out as poor abstraction.**

✅ **Each subsystem initializes itself:**
```python
class DatabaseSystem:
    """Abstraction: Database operations."""
    def initialize(self):
        # Database-specific initialization
        pass

class WebServer:
    """Abstraction: Web serving."""
    def start(self):
        # Web server initialization
        pass

class BackgroundJobManager:
    """Abstraction: Job processing."""
    def start(self):
        # Job system initialization
        pass

# Coordinator stays high-level
class Application:
    def __init__(self):
        self.database = DatabaseSystem()
        self.web_server = WebServer()
        self.jobs = BackgroundJobManager()

    def start(self):
        # High-level orchestration
        self.database.initialize()
        self.web_server.start()
        self.jobs.start()
```

**Now:** Each class has consistent abstraction. Program no longer a grab-bag.

### Anti-Pattern 3: Business Logic + Persistence Mixed

**Baseline violation:**
```python
class DataProcessor:
    """Mixes data access with statistics."""
    def process_dataset(self, dataset_id):
        # Loads from PostgreSQL (persistence concern)
        values = self._load_dataset(dataset_id)

        # Calculates statistics (business logic concern)
        mean = statistics.mean(values)

        # Two concerns in one class
```

**Problem:** Class does two things - data access AND statistics. If you switch from PostgreSQL to MongoDB, you must modify this class. If you change statistical algorithm, you modify same class.

✅ **Separate concerns:**
```python
class DatasetRepository:
    """Abstraction: Dataset storage/retrieval."""
    def get_dataset_values(self, dataset_id: str) -> list[float]:
        # PostgreSQL details hidden here
        # Can switch to MongoDB without affecting calculator
        pass

class StatisticsCalculator:
    """Abstraction: Statistical computations."""
    def calculate_metrics(self, values: list[float]) -> dict:
        # Pure calculation, no database knowledge
        mean = statistics.mean(values)
        median = statistics.median(values)
        # Returns statistics only
        pass

class DataProcessor:
    """Abstraction: Orchestration."""
    def __init__(self, repository, calculator):
        self._repository = repository
        self._calculator = calculator

    def process_dataset(self, dataset_id: str) -> dict:
        # High-level only - delegates to focused abstractions
        values = self._repository.get_dataset_values(dataset_id)
        return self._calculator.calculate_metrics(values)
```

**Now:** Each class has single, consistent abstraction. Database changes don't affect calculator. Algorithm changes don't affect repository.

## The Abstraction Levels Test

**For any class, ask:**

1. **What abstraction does this class represent?**
   - Can state it in one sentence?
   - All methods work toward that one purpose?

2. **Are all methods at same abstraction level?**
   - All high-level (orchestration)?
   - All low-level (implementation)?
   - Or mixed (violation)?

3. **Do methods belong together?**
   - Related by purpose (functional cohesion)?
   - Or just coincidentally grouped (temporal/coincidental)?

**If answers reveal inconsistency → poor abstraction.**

## Types of Cohesion (Worst to Best)

### Coincidental (Worst)

**Unrelated things in one class:**
```python
class Utilities:
    def validate_email(self):  # Validation
    def format_currency(self):  # Formatting
    def connect_database(self):  # Database
```

**No relationship. Avoid this.**

### Temporal (Weak)

**Things done at same time:**
```python
class Startup:
    def init_database(self):  # Done at startup
    def init_webserver(self):  # Done at startup
    def init_logging(self):  # Done at startup
```

**Related by WHEN not WHAT. Weak abstraction.**

### Functional (Best)

**One clear purpose:**
```python
class EmployeeCalculations:
    def calculate_annual_salary(self, employee):
    def calculate_tax_withholding(self, employee):
    def calculate_benefits_cost(self, employee):
```

**All methods work toward one purpose. Best abstraction.**

**Always aim for functional cohesion.**

## Quick Reference

| Violation | Example | Fix |
|-----------|---------|-----|
| **Domain + Format mixed** | `Employee.to_json()` | Separate Serializer class |
| **Business + Persistence mixed** | `OrderProcessor` with SQL | Separate Repository from logic |
| **High + Low level mixed** | Orchestration with SQL queries | Extract low-level to private/separate |
| **Grab-bag class** | `Utilities`, `Program`, `Helpers` | Split by actual purpose |
| **Temporal cohesion** | Startup class with unrelated inits | Each subsystem owns initialization |

## Consistent Abstraction Examples

### Good: Employee (Domain Only)

```python
class Employee:
    """Abstraction: Employee domain model."""
    # All methods are employee operations
    def calculate_annual_salary(self):
    def update_department(self, dept):
    def get_compensation_summary(self):
    def is_eligible_for_bonus(self):
```

**Consistent: All domain operations about employees.**

### Bad: Employee with Mixed Concerns

```python
class Employee:
    """Mixed abstraction - unclear purpose."""
    def calculate_annual_salary(self):  # Domain
    def to_json(self):  # Serialization
    def save_to_database(self):  # Persistence
    def send_welcome_email(self):  # Notification
```

**Inconsistent: Domain + serialization + persistence + notifications.**

## When to Split a Class

**Split when:**
1. Class has multiple reasons to change (SRP violation)
2. Methods at different abstraction levels
3. Can't state class purpose in one sentence
4. Methods group into distinct clusters
5. Some methods don't use instance data

**Example split:**
```python
# Before: One class, mixed abstractions
class UserService:
    def create_user(self, email, name):
        # Validation
        if not self._is_valid_email(email):
            raise ValueError()

        # Create domain object
        user = User(email, name)

        # Persist to database
        self._db.execute("INSERT INTO users ...")

        # Send welcome email
        self._smtp.send(email, "Welcome!")

        return user

# After: Focused classes
class UserValidator:
    """Abstraction: Validation."""
    def validate_registration(self, email, name):
        pass

class UserRepository:
    """Abstraction: Persistence."""
    def save_user(self, user):
        pass

class UserNotifier:
    """Abstraction: Notifications."""
    def send_welcome_email(self, user):
        pass

class UserService:
    """Abstraction: Orchestration."""
    def create_user(self, email, name):
        self._validator.validate_registration(email, name)
        user = User(email, name)
        self._repository.save_user(user)
        self._notifier.send_welcome_email(user)
        return user
```

## Red Flags - Poor Abstraction

**Class level:**
- Can't explain what abstraction class represents
- Methods don't seem related
- Some methods at high level, some at low level
- Class name is vague (`Manager`, `Handler`, `Processor`, `Utility`)
- Class description lists multiple unrelated purposes

**Method level:**
- Domain method mixed with serialization (`to_json`)
- Business logic mixed with SQL queries
- High-level orchestration with low-level details inline
- Method doesn't fit with others in class

**All of these mean: Improve abstraction consistency.**

## Common Rationalizations

From baseline testing:

| Excuse | Reality |
|--------|---------|
| "Keeps everything in one place" | One place ≠ good organization. Split by purpose, not location. |
| "It's just a coordinator" | Coordinators coordinate related things. Unrelated = grab-bag. |
| "Easier than multiple classes" | Easier to write ≠ easier to maintain. Abstraction quality matters. |
| "Production-ready code" | Working ≠ well-abstracted. Can be both. |
| "All used during startup" | Temporal relationship is weak. Use functional relationships. |
| "Serialization is part of the object" | No - serialization is a separate concern. External responsibility. |

## Verification Checklist

For each class, verify:

- [ ] Can state what abstraction this class represents in one sentence
- [ ] All methods work toward that one abstraction
- [ ] All methods at consistent abstraction level
- [ ] No serialization mixed with domain (no to_json, to_xml in domain classes)
- [ ] No persistence mixed with business logic (no SQL in calculation classes)
- [ ] No grab-bag/utility classes with unrelated functions
- [ ] Functional cohesion (related by purpose) not temporal (related by timing)
- [ ] Class name reflects clear purpose, not vague role

**If any "no" → split class or clarify abstraction.**

## Real-World Impact

From Code Complete:
- Abstract Data Types (ADTs) are foundation of classes
- Each class should implement one and only one ADT
- Poor abstraction = miscellaneous collection with no clear purpose
- Study found 30%+ comprehension improvement with good abstractions

From baseline testing:
- Agents mixed domain with serialization (Employee.to_json)
- Created grab-bag classes (Program with unrelated inits)
- Mixed business logic with persistence (DataProcessor, OrderProcessor)
- Good instinct: extracted to methods
- Bad pattern: didn't separate into classes

**With this skill:** Separate concerns, maintain abstraction consistency, functional cohesion.

## Integration with Other Skills

**For single responsibility:** See @../../coding/keeping-routines-focused/SKILL.md - same principle applies to classes (one clear purpose)

**For encapsulation:** See @../encapsulating-complexity/SKILL.md - hiding implementation details supports abstraction consistency

**For complexity:** See @../reducing-complexity/SKILL.md - consistent abstractions reduce mental load
