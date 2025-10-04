# Architecture Skills

Patterns for designing systems and data structures.

## Available Skills

- @reducing-complexity/SKILL.md - Managing complexity is software's primary technical imperative - all other goals are secondary. Use before and during any design or implementation, when solution feels complicated, when code is hard to understand, when complexity is proliferating.

- @encapsulating-complexity/SKILL.md - Hide implementation details behind interfaces - work at domain level (what), not implementation level (how). Use when designing any class or interface, when implementation details leak into public API, when storage format is exposed, when working with raw data structures instead of domain objects, when changing implementation would break client code.

- @maintaining-consistent-abstractions/SKILL.md - Class interfaces present one cohesive abstraction - don't mix domain logic with serialization, persistence, or unrelated concerns. Use when designing any class interface, when class has mixed responsibilities, when domain object knows about JSON/database, when temporal cohesion exists (grouped by when not what), when creating utility/grab-bag classes.

## Core Principles

These skills implement fundamental design principles:

**1. Complexity as Primary Imperative**
- Minimize complexity above all other goals (reducing-complexity)
- Break into simple pieces, minimize what you must understand at once

**2. Information Hiding**
- Hide implementation details behind abstractions (encapsulating-complexity)
- Work at domain level (what) not implementation level (how)
- Separate concerns, change implementation without breaking clients

**3. Abstraction Quality**
- Each class represents ONE cohesive abstraction (maintaining-consistent-abstractions)
- Don't mix domain with serialization/persistence
- Avoid grab-bag classes with unrelated functions
- Functional cohesion (related by purpose) not temporal (related by timing)
