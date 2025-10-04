---
name: Encapsulating Complexity
description: Hide implementation details behind interfaces - work at domain level (what), not implementation level (how)
when_to_use: When designing any class or interface. When implementation details leak into public API. When storage format (JSON, SQL, files) is exposed. When working with raw data structures (dicts, rows) instead of domain objects. When client code must know HOW things work internally. When changing implementation would break client code. When database queries mixed with business logic. When switching storage type requires interface changes. When tests must know internal structure.
version: 1.0.0
languages: all
type: pattern
---

# Encapsulating Complexity

## Overview

Hide HOW things work. Expose only WHAT they do. Work at domain level (Users, Orders, Config), not implementation level (dicts, SQL rows, JSON files).

**Core principle:** The point of encapsulation is to create possibilities (many ways to implement) and restrict possibilities (one way to use). Implementation details hidden = free to change implementation without breaking clients.

**Violating the letter of this rule is violating the spirit of information hiding.**

## When to Use

**Apply to every class and interface:**
- Designing new classes/modules
- Creating public APIs
- Reviewing code for abstraction leaks
- Refactoring to improve maintainability

**Warning signs you're violating encapsulation:**
- Client code knows storage format (JSON, SQL, files)
- Interface exposes database/file operations
- Returns raw dicts/rows instead of domain objects
- Client code constructs SQL queries or file paths
- Changing from JSON to YAML breaks client code
- Switching databases requires changing all callers
- Tests must know internal data structures
- Method names reveal implementation (saveToJSON, queryDatabase)
- Public fields exposing internal state

## The Encapsulation Test

**Ask these questions about every public method/field:**

1. **Does the interface expose HOW or WHAT?**
   - "Get user" = WHAT (good)
   - "SELECT * FROM users" = HOW (bad)

2. **Can I change implementation without breaking clients?**
   - JSON → YAML: should work
   - PostgreSQL → MongoDB: should work
   - If clients break: encapsulation violated

3. **Do clients work at domain level or implementation level?**
   - Domain: `user.email`, `config.get_timeout()`
   - Implementation: `row[2]`, `json_data['timeout_ms']`

4. **Do return values expose internals?**
   - Domain: `User` object
   - Implementation: `dict` with database column names

**If answers reveal implementation details → encapsulation violated.**

## Core Pattern: Hide the How

### Before (Implementation Exposed)

```python
class ConfigManager:
    def __init__(self, json_path):
        self.json_path = json_path  # ❌ Exposes JSON
        self._data = {}

    def get_value(self, key):
        return self._data.get(key)  # ⚠️ Returns raw value

    def save_to_json(self):  # ❌ "JSON" in method name
        with open(self.json_path, 'w') as f:
            json.dump(self._data, f)
```

**Client code:**
```python
config = ConfigManager("/path/to/config.json")  # Must know it's JSON
timeout = config.get_value("timeout_ms")  # Must know exact key format
config.save_to_json()  # Tied to JSON format
```

**If you switch JSON → YAML:** Client code breaks. Method names wrong. Constructor signature wrong.

### After (Implementation Hidden)

```python
class Config:
    def __init__(self, config_file):  # ✅ No format specified
        self._storage = self._load(config_file)  # ✅ Implementation hidden

    def get_timeout(self):  # ✅ Domain method, not raw key access
        return self._storage.get("timeout_ms", 5000)

    def set_timeout(self, seconds):  # ✅ Domain operation
        self._storage["timeout_ms"] = seconds * 1000  # ms internally

    def save(self):  # ✅ No "JSON" in name
        self._persist(self._storage)

    def _load(self, config_file):  # ✅ Private - can change format
        # Could load JSON, YAML, TOML, etc.
        pass

    def _persist(self, data):  # ✅ Private - implementation detail
        # Format hidden from clients
        pass
```

**Client code:**
```python
config = Config("app.config")  # Format agnostic
timeout = config.get_timeout()  # Domain method (seconds)
config.set_timeout(10)
config.save()
```

**Switch JSON → YAML:** Client code unchanged. Just change `_load()` and `_persist()`.

## Domain Level vs Implementation Level

**Work at the problem domain, not the solution domain:**

### Example 1: User Management

❌ **Implementation Level:**
```python
class UserManager:
    def get_user_row(self, user_id):
        # Returns database row as dict
        cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        return dict(cur.fetchone())  # ❌ Raw row dict

    def update_user_column(self, user_id, column, value):
        # ❌ Exposes database columns
        cur.execute(f"UPDATE users SET {column} = %s WHERE id = %s", ...)
```

**Client must know:**
- Database schema (column names)
- SQL concepts (rows, columns)
- Data types in database

✅ **Domain Level:**
```python
class UserRepository:
    def get_user(self, user_id: str) -> User:
        # Returns domain object
        row = self._query_user(user_id)
        return User.from_storage(row)  # ✅ Domain object

    def update_email(self, user_id: str, new_email: str) -> None:
        # ✅ Domain operation, no column names
        user = self.get_user(user_id)
        user.email = new_email
        self._persist_user(user)

class User:
    def __init__(self, id, email, name):
        self.id = id
        self.email = email
        self.name = name
```

**Client knows:**
- Users (domain concept)
- Email (domain field)
- Nothing about database

### Example 2: Configuration

❌ **Implementation Level:**
```python
class ConfigManager:
    def get(self, key):
        return self._config.get(key)  # ❌ Must know exact key names

    # Client code
    timeout = config.get("server.timeout_milliseconds")  # ❌ Internal structure
    port = config.get("server.port")
```

✅ **Domain Level:**
```python
class Config:
    def server_timeout(self):  # ✅ Domain method
        return self._get("server.timeout_ms", 5000) / 1000  # Hide ms→sec

    def server_port(self):  # ✅ Domain method
        return self._get("server.port", 8080)

    # Client code
    timeout = config.server_timeout()  # ✅ Clean domain API
    port = config.server_port()
```

## Separation of Concerns

**Don't mix persistence with domain logic:**

❌ **Mixed (From Baseline Test):**
```python
class ReportGenerator:
    def generate(self, start_date, end_date):
        # Database access
        conn = psycopg2.connect(...)
        cursor.execute("SELECT ...")
        rows = cursor.fetchall()

        # Business logic
        total = sum(row[3] for row in rows)

        # HTML formatting
        html = f"<html>...</html>"

        # File I/O
        with open(f"report_{start_date}.html", "w") as f:
            f.write(html)
```

**4 concerns mixed: database, calculation, formatting, file I/O**

✅ **Separated:**
```python
class SalesRepository:
    """Concern: Data access"""
    def get_sales(self, start_date, end_date) -> List[Sale]:
        # Database logic hidden here
        pass

class SalesCalculator:
    """Concern: Business logic"""
    def calculate_metrics(self, sales: List[Sale]) -> SalesMetrics:
        # Pure calculation, no database/file knowledge
        pass

class HTMLFormatter:
    """Concern: Presentation"""
    def format_report(self, metrics: SalesMetrics) -> str:
        # HTML generation, no database/calculation knowledge
        pass

class ReportGenerator:
    """Concern: Orchestration"""
    def __init__(self, repo, calculator, formatter):
        self._repo = repo
        self._calculator = calculator
        self._formatter = formatter

    def generate(self, start_date, end_date, output_path):
        sales = self._repo.get_sales(start_date, end_date)  # What
        metrics = self._calculator.calculate_metrics(sales)  # What
        html = self._formatter.format_report(metrics)  # What

        with open(output_path, "w") as f:
            f.write(html)
```

**Each class can change independently. Database switch doesn't touch formatting. HTML→PDF doesn't touch database.**

## What to Hide

### Hide Storage Format

❌ **Exposed:**
```python
class DataStore:
    def load_from_json(self):  # ❌ "JSON" in name
        pass

    def save_to_json(self):  # ❌ Tied to JSON
        pass
```

✅ **Hidden:**
```python
class DataStore:
    def load(self):  # ✅ Format agnostic
        self._read_storage()  # Private - can be JSON/YAML/SQL

    def save(self):  # ✅ Format agnostic
        self._write_storage()  # Private - implementation hidden
```

### Hide Database Details

❌ **Exposed:**
```python
def get_users(self):
    cur.execute("SELECT * FROM users")
    return [dict(row) for row in cur.fetchall()]  # ❌ Raw database rows
```

✅ **Hidden:**
```python
def get_users(self) -> List[User]:
    rows = self._query_all_users()  # SQL hidden in private method
    return [User.from_row(row) for row in rows]  # ✅ Domain objects
```

### Hide Data Structures

❌ **Exposed:**
```python
class UserCache:
    def __init__(self):
        self.users_dict = {}  # ❌ Public dict

    # Client code manipulates dict directly
    cache.users_dict[user_id] = user_data
```

✅ **Hidden:**
```python
class UserCache:
    def __init__(self):
        self._storage = {}  # ✅ Private implementation

    def add_user(self, user):  # ✅ Domain operation
        self._storage[user.id] = user

    def get_user(self, user_id):  # ✅ Domain operation
        return self._storage.get(user_id)
```

**Internal dict can become Redis, Memcached, or database without breaking clients.**

### Hide Algorithms and Complexity

❌ **Exposed:**
```python
def sort_users_by_name(users):
    # ❌ Client must understand sorting implementation
    # Uses quicksort internally
    return quicksort(users, key=lambda u: u.name)
```

✅ **Hidden:**
```python
def get_users_sorted_by_name(users):
    # ✅ How it sorts is hidden - could be quicksort, mergesort, timsort
    return sorted(users, key=lambda u: u.name)
```

## Interface Design Principles

### 1. Name by What, Not How

❌ **How (implementation exposed):**
- `save_to_json()`, `load_from_yaml()`, `write_to_file()`
- `execute_sql_query()`, `get_database_connection()`
- `parse_json_response()`, `build_xml_request()`

✅ **What (implementation hidden):**
- `save()`, `load()`, `persist()`
- `get_users()`, `find_by_email()`
- `send_request()`, `get_response()`

### 2. Accept and Return Domain Objects

❌ **Raw data structures:**
```python
def create_user(self, user_dict: dict) -> dict:
    # ❌ Accepts and returns dicts
    # Client must know dict structure
```

✅ **Domain objects:**
```python
def create_user(self, email: str, name: str) -> User:
    # ✅ Clear parameters, returns domain object
    # Internal structure hidden
```

### 3. Work at Single Abstraction Level

❌ **Mixed levels:**
```python
def process_order(self, order):
    validate_order(order)  # High level

    # ❌ Low-level SQL mixed in
    conn.execute("INSERT INTO orders VALUES (%s, %s)", ...)

    send_confirmation(order)  # High level
```

✅ **Consistent level:**
```python
def process_order(self, order):
    # All high level - persistence hidden
    validate_order(order)
    saved_order = self._repository.save(order)  # Hides SQL
    send_confirmation(saved_order)
```

## Common Violations from Baseline Testing

### Violation 1: Exposing Storage Format

**Baseline:** ConfigManager exposes JSON in interface, UserManager exposes SQL.

❌ **What agents naturally do:**
```python
class ConfigManager:
    def __init__(self, json_path):  # Exposes JSON
        self.json_path = json_path  # Public attribute

    def save(self):
        with open(self.json_path, 'w') as f:
            json.dump(self._config, f)  # JSON logic in public view
```

✅ **Hide format:**
```python
class Config:
    def __init__(self, config_file):  # ✅ Format neutral
        self._loader = self._create_loader(config_file)  # Private
        self._data = self._loader.load()  # Hidden

    def save(self):
        self._loader.persist(self._data)  # ✅ Format hidden

    def _create_loader(self, config_file):
        # Private - can support JSON, YAML, TOML, etc.
        if config_file.endswith('.yaml'):
            return YAMLLoader(config_file)
        return JSONLoader(config_file)  # Default
```

### Violation 2: Working at Implementation Level

**Baseline:** UserManager returns dicts, exposes column names.

❌ **What agents naturally do:**
```python
def get_user(self, user_id):
    cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    return dict(cur.fetchone())  # ❌ Raw database row

# Client must know database schema
user_dict = manager.get_user(123)
email = user_dict['email']  # ❌ Column name knowledge required
```

✅ **Work at domain level:**
```python
def get_user(self, user_id: str) -> User:
    row = self._fetch_user_row(user_id)  # SQL hidden
    return User(
        id=row['id'],
        email=row['email'],
        name=row['name']
    )  # ✅ Domain object

# Client works with domain concepts
user = repo.get_user("123")
email = user.email  # ✅ Domain field, not column
```

### Violation 3: Mixed Concerns

**Baseline:** ReportGenerator mixes database, calculation, formatting, file I/O in one method.

❌ **What agents naturally do:**
```python
def generate_report(self):
    conn = psycopg2.connect(...)  # Database
    rows = cursor.fetchall()  # Database
    total = sum(row[3] for row in rows)  # Calculation
    html = f"<html>...</html>"  # Formatting
    with open("report.html", "w") as f:  # File I/O
        f.write(html)
```

✅ **Separate and encapsulate:**
```python
class ReportGenerator:
    def __init__(self, repo, calculator, formatter, file_writer):
        self._repo = repo  # Database concern encapsulated
        self._calculator = calculator  # Calculation encapsulated
        self._formatter = formatter  # Formatting encapsulated
        self._writer = file_writer  # I/O encapsulated

    def generate(self, start_date, end_date):
        # Orchestrate without knowing HOW each works
        sales = self._repo.get_sales(start_date, end_date)
        metrics = self._calculator.calculate(sales)
        content = self._formatter.format(metrics)
        return self._writer.write(content)
```

## Quick Reference

| Encapsulation Target | What to Hide | What to Expose |
|----------------------|--------------|----------------|
| **Storage format** | JSON/YAML/SQL/files | `load()`, `save()` |
| **Database** | SQL queries, connection, schema | Domain operations (`get_user()`) |
| **Data structures** | Dict/list/tree internal structure | Domain methods |
| **Algorithms** | Sorting/searching implementation | High-level operation |
| **File paths** | Internal directory structure | Logical identifiers |
| **External APIs** | HTTP/gRPC/REST details | Domain operations |
| **Complex state** | State machine internals | Simple operations |

## Techniques for Encapsulation

### Technique 1: Private Implementation Methods

```python
class UserRepository:
    # ✅ Public interface - domain level
    def find_by_email(self, email: str) -> Optional[User]:
        row = self._query_by_email(email)  # Call private method
        return User.from_row(row) if row else None

    # ✅ Private implementation - can change freely
    def _query_by_email(self, email: str):
        # SQL hidden in private method
        # Can change SQL, database, caching without affecting public interface
        pass
```

### Technique 2: Adapter/Wrapper Pattern

```python
# ✅ Wrap complex external library behind simple interface
class EmailService:
    def __init__(self):
        self._smtp_client = smtplib.SMTP(...)  # ✅ Private
        self._templates = self._load_templates()  # ✅ Private

    def send_welcome_email(self, user: User):
        # ✅ Domain operation, SMTP hidden
        template = self._templates['welcome']
        message = template.format(name=user.name)
        self._smtp_client.send(user.email, message)
```

### Technique 3: Abstract Data Types

```python
# ✅ Font operations at problem level, not bit manipulation
class Font:
    def set_bold(self):
        # Hides bit manipulation: attr = attr | 0x02
        self._attributes |= self.BOLD_FLAG

    def is_bold(self):
        return bool(self._attributes & self.BOLD_FLAG)
```

**Client code:** `font.set_bold()` not `font.attr = font.attr | 0x02`

### Technique 4: Facade for Complex Subsystems

```python
# ✅ Simple interface hiding complex subsystem
class OrderProcessor:
    """Facade hiding inventory, payment, shipping complexity."""

    def __init__(self):
        self._inventory = InventorySystem()  # Complex
        self._payment = PaymentGateway()  # Complex
        self._shipping = ShippingService()  # Complex

    def place_order(self, order: Order) -> OrderResult:
        # ✅ Simple interface, complex coordination hidden
        self._inventory.reserve(order.items)
        self._payment.charge(order.payment_info)
        self._shipping.create_shipment(order.address)
        return OrderResult(success=True, order_id=order.id)
```

## Layering and Stratification

**Create layers where each hides complexity of layer below:**

```
┌─────────────────────────────┐
│  Application Layer          │  Works with: Users, Orders (domain)
├─────────────────────────────┤
│  Domain Layer               │  Works with: Entities, Value Objects
├─────────────────────────────┤
│  Persistence Layer          │  Works with: Rows, JSON (hidden)
├─────────────────────────────┤
│  Database/Storage           │  SQL, files (fully hidden)
└─────────────────────────────┘
```

**Each layer:**
- Encapsulates complexity of layers below
- Presents abstraction to layers above
- Can be changed without affecting other layers

## Benefits of Encapsulation

### 1. Change Implementation Freely

```python
# Can change from JSON to YAML
# Can change from PostgreSQL to MongoDB
# Can change from files to cloud storage
# WITHOUT changing client code
```

### 2. Simpler Client Code

```python
# ❌ Without encapsulation
config_data = json.load(open("config.json"))
timeout = config_data.get("server", {}).get("timeout_ms", 5000) / 1000

# ✅ With encapsulation
timeout = config.server_timeout()
```

### 3. Easier Testing

```python
# ✅ Can mock at domain level
mock_repo = Mock(UserRepository)
mock_repo.get_user.return_value = User("1", "test@test.com", "Test")

# Don't need to mock:
# - Database connections
# - SQL queries
# - Row dictionaries
```

### 4. Prevents Ripple Effects

```python
# Change database schema:
# - With encapsulation: Change private methods only
# - Without: Change every place that accesses row['column_name']
```

## Common Mistakes

**❌ Exposing internal structure:**
```python
class ShoppingCart:
    def __init__(self):
        self.items = []  # ❌ Public list - clients depend on list structure
```

**✅ Hide structure:**
```python
class ShoppingCart:
    def __init__(self):
        self._items = []  # ✅ Private - can change to set, dict, etc.

    def add_item(self, item):  # ✅ Domain operation
        self._items.append(item)

    def get_items(self):  # ✅ Returns copy or iterator
        return list(self._items)
```

---

**❌ Returning mutable internal state:**
```python
def get_config_dict(self):
    return self._config  # ❌ Clients can modify internal state
```

✅ **Return copies or immutable:**
```python
def get_config_dict(self):
    return dict(self._config)  # ✅ Copy - changes don't affect internal
```

---

**❌ Method names revealing implementation:**
```python
get_json_data(), save_to_database(), execute_sql(), write_file()
```

✅ **Method names revealing purpose:**
```python
get_data(), save(), persist(), execute(), write()
```

## Red Flags - Improve Encapsulation

**Interface design:**
- Method names mention implementation (JSON, SQL, HTTP, file)
- Returns raw dicts/rows/JSON instead of domain objects
- Accepts raw data instead of domain parameters
- Public fields exposing internal state
- Client code must know storage format

**Implementation:**
- Database queries in business logic classes
- File I/O mixed with calculations
- Multiple concerns in one class
- Working with rows/dicts instead of domain objects
- Switching implementation would break clients

**All of these mean: Improve encapsulation.**

## Common Rationalizations

From baseline testing, agents justify poor encapsulation with:

| Excuse | Reality |
|--------|---------|
| "Client needs to know the structure" | No, client needs domain operations. Hide structure. |
| "Returning dict is simpler than creating class" | Simple to write ≠ simple to maintain. Domain objects prevent errors. |
| "Just a thin wrapper, not worth it" | Wrappers enable change. Worth it. |
| "Everything's in one place, easier to find" | Easier to find ≠ easier to change. Separation enables modification. |
| "It works, no need to abstract" | Working now ≠ maintainable later. Abstract anyway. |
| "YAGNI - we won't change database" | Can't predict future. Encapsulation is cheap insurance. |
| "Too much boilerplate" | Boilerplate prevents ripple effects. Trade-off worth it. |

## Verification Checklist

Before marking class/interface design complete:

- [ ] Method names reveal purpose, not implementation
- [ ] Returns domain objects, not raw dicts/rows
- [ ] Accepts domain parameters, not raw data structures
- [ ] No public fields exposing internal state
- [ ] Can change storage format without breaking clients
- [ ] Can change database without changing interface
- [ ] Client works at domain level (User, Order) not implementation level (dict, row)
- [ ] Mixed concerns separated (persistence, logic, formatting)
- [ ] Private methods hide implementation details
- [ ] Tests don't depend on internal structure

**If any "no" → improve encapsulation.**

## Real-World Impact

From Code Complete:
- Information hiding is fundamental design heuristic
- Classes should hide their implementation behind interfaces
- Work at problem domain level, not solution domain level
- Benefits: easier to modify, reuse, and understand

From baseline testing:
- Agents naturally use private variables (`_config`)
- BUT expose storage format (JSON, SQL)
- Work at implementation level (dicts, rows) not domain (objects)
- Mix concerns (database + calculation + formatting)
- Don't create domain objects - return raw data

**With this skill:** Hide implementation, work at domain level, separate concerns.

## Integration with Other Skills

**For keeping interfaces focused:** See @../../coding/keeping-routines-focused/SKILL.md - single responsibility applies to classes too

**For reducing complexity:** See @../reducing-complexity/SKILL.md - encapsulation reduces complexity by hiding details
