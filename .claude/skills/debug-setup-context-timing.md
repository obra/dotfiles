```dot
digraph DEBUG_SETUP_CONTEXT_TIMING {
    label="Fixing Tests Accessing Setup Context Before Hooks Run";

    // Entry
    "Start: Tests using empty/wrong values from setup" [shape=doublecircle];

    // Symptom recognition
    "See errors with empty strings or wrong paths?" [shape=diamond];
    "Check if using setupTest() context" [shape=box];

    // Root cause identification
    "Is context accessed at top level?" [shape=diamond];
    "Check variable declarations" [shape=box];
    "const ctx = setupTest(); ... ctx.value" [shape=plaintext];

    // THE PROBLEM
    "PROBLEM: setupTest() returns object with empty initial values" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
    "PROBLEM: Values populated in beforeEach hook" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
    "PROBLEM: Top-level access gets empty values" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];

    // Solutions
    "Which fix?" [shape=diamond];

    // Solution 1: Make value a getter
    "Solution 1: Convert to getter with validation" [shape=box];
    "Make value a closure variable" [shape=box];
    "Return getter that throws if not set" [shape=box];
    "get value() { if (!_value) throw ... }" [shape=plaintext];

    // Solution 2: Fix test usage
    "Solution 2: Don't access at top level" [shape=box];
    "Access value ONLY in beforeEach/it blocks" [shape=box];
    "let myVar; beforeEach(() => { myVar = ctx.value })" [shape=plaintext];

    // Validation
    "Run tests" [shape=box];
    "npm test" [shape=plaintext];
    "Do tests fail with clear error?" [shape=diamond];
    "Error says accessed before hook?" [shape=diamond];

    // Success
    "Tests fail fast with helpful message" [shape=doublecircle];
    "Fix test to access in beforeEach" [shape=box];
    "All tests pass" [shape=doublecircle];

    // Flow
    "Start: Tests using empty/wrong values from setup" -> "See errors with empty strings or wrong paths?";
    "See errors with empty strings or wrong paths?" -> "Check if using setupTest() context" [label="yes"];
    "Check if using setupTest() context" -> "Is context accessed at top level?";

    "Is context accessed at top level?" -> "Check variable declarations" [label="yes"];
    "Check variable declarations" -> "const ctx = setupTest(); ... ctx.value";
    "const ctx = setupTest(); ... ctx.value" -> "PROBLEM: setupTest() returns object with empty initial values";

    "PROBLEM: setupTest() returns object with empty initial values" -> "PROBLEM: Values populated in beforeEach hook";
    "PROBLEM: Values populated in beforeEach hook" -> "PROBLEM: Top-level access gets empty values";
    "PROBLEM: Top-level access gets empty values" -> "Which fix?";

    "Which fix?" -> "Solution 1: Convert to getter with validation" [label="prefer: infrastructure fix"];
    "Which fix?" -> "Solution 2: Don't access at top level" [label="if can't change infrastructure"];

    "Solution 1: Convert to getter with validation" -> "Make value a closure variable";
    "Make value a closure variable" -> "Return getter that throws if not set";
    "Return getter that throws if not set" -> "get value() { if (!_value) throw ... }";
    "get value() { if (!_value) throw ... }" -> "Run tests";

    "Solution 2: Don't access at top level" -> "Access value ONLY in beforeEach/it blocks";
    "Access value ONLY in beforeEach/it blocks" -> "let myVar; beforeEach(() => { myVar = ctx.value })";
    "let myVar; beforeEach(() => { myVar = ctx.value })" -> "Run tests";

    "Run tests" -> "npm test";
    "npm test" -> "Do tests fail with clear error?";
    "Do tests fail with clear error?" -> "Error says accessed before hook?" [label="yes"];
    "Error says accessed before hook?" -> "Tests fail fast with helpful message" [label="yes"];

    "Tests fail fast with helpful message" -> "Fix test to access in beforeEach";
    "Fix test to access in beforeEach" -> "All tests pass";

    // Key patterns
    subgraph cluster_patterns {
        label="CODE PATTERNS";

        // Bad pattern
        bad_before [label="❌ BAD:\nconst ctx = setup();\nProject.create('name', ctx.tempDir, ...)", shape=plaintext];

        // Good pattern
        good_after [label="✅ GOOD:\nconst ctx = setup();\nlet tempDir;\nbeforeEach(() => { tempDir = join(ctx.tempDir, 'proj') })\nProject.create('name', tempDir, ...)", shape=plaintext];

        // Getter pattern
        getter_pattern [label="✅ INFRASTRUCTURE FIX:\nlet _value = '';\nreturn {\n  get value() {\n    if (!_value) throw Error('...');\n    return _value;\n  }\n}", shape=plaintext];
    }
}
```

**When to use:** Tests fail with empty strings, undefined values, or wrong paths that come from test setup utilities.

**Root cause:** Test setup functions return objects with initial empty values, populated later in hooks. Top-level access gets empty values.

**Best fix:** Convert values to getters with validation (infrastructure fix, catches all cases).

**Alternative:** Fix tests to not access at top level (symptom fix, error-prone).
