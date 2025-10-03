```dot
digraph TRACE_BAD_INITIALIZATION {
    label="Using Stack Traces to Find Where Bad Initialization Happens";

    // Entry
    "Start: Something initialized with wrong value" [shape=doublecircle];

    // Examples
    "Examples: git init in wrong dir, DB created in wrong path, file created in wrong location" [shape=ellipse];

    // Find the initialization code
    "Locate initialization code" [shape=box];
    "grep -rn 'git init\\|mkdir\\|writeFile' src" [shape=plaintext];

    // Add stack trace logging
    "Add stack trace capture" [shape=box];
    "const stack = new Error().stack" [shape=plaintext];

    // Log before action
    "Log stack BEFORE the operation" [shape=box];
    "console.error('DEBUG:', { path, cwd, stack })" [shape=plaintext];

    // Critical: Use console.error not logger
    "CRITICAL: Use console.error in tests" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
    "logger may not show in test output" [shape=octagon, style=filled, fillcolor=yellow];

    // Run tests
    "Run tests with output capture" [shape=box];
    "npm test 2>&1 | grep 'DEBUG:'" [shape=plaintext];

    // Analyze stack traces
    "Review captured stack traces" [shape=box];
    "Look for test file names in stack" [shape=box];
    "Find the calling test at line X" [shape=box];

    // Identify pattern
    "Pattern in stack traces?" [shape=diamond];
    "Same test file repeatedly?" [shape=diamond];
    "Same caller function?" [shape=diamond];

    // Root cause
    "Identify root cause from pattern" [shape=box];
    "Examples: wrong parameter order, missing validation, timing issue" [shape=ellipse];

    // Fix
    "Apply targeted fix" [shape=box];
    "Remove debug logging" [shape=box];
    "Verify with clean test run" [shape=box];

    // Success
    "All tests pass, no pollution" [shape=doublecircle];

    // Flow
    "Start: Something initialized with wrong value" -> "Examples: git init in wrong dir, DB created in wrong path, file created in wrong location";
    "Examples: git init in wrong dir, DB created in wrong path, file created in wrong location" -> "Locate initialization code";

    "Locate initialization code" -> "grep -rn 'git init\\|mkdir\\|writeFile' src";
    "grep -rn 'git init\\|mkdir\\|writeFile' src" -> "Add stack trace capture";

    "Add stack trace capture" -> "const stack = new Error().stack";
    "const stack = new Error().stack" -> "Log before action";
    "Log before action" -> "console.error('DEBUG:', { path, cwd, stack })";
    "console.error('DEBUG:', { path, cwd, stack })" -> "CRITICAL: Use console.error in tests";

    "CRITICAL: Use console.error in tests" -> "logger may not show in test output" [style=dotted];
    "CRITICAL: Use console.error in tests" -> "Run tests with output capture";

    "Run tests with output capture" -> "npm test 2>&1 | grep 'DEBUG:'";
    "npm test 2>&1 | grep 'DEBUG:'" -> "Review captured stack traces";

    "Review captured stack traces" -> "Look for test file names in stack";
    "Look for test file names in stack" -> "Find the calling test at line X";
    "Find the calling test at line X" -> "Pattern in stack traces?";

    "Pattern in stack traces?" -> "Same test file repeatedly?" [label="yes"];
    "Same test file repeatedly?" -> "Same caller function?" [label="yes"];
    "Same caller function?" -> "Identify root cause from pattern" [label="yes"];

    "Identify root cause from pattern" -> "Examples: wrong parameter order, missing validation, timing issue";
    "Examples: wrong parameter order, missing validation, timing issue" -> "Apply targeted fix";

    "Apply targeted fix" -> "Remove debug logging";
    "Remove debug logging" -> "Verify with clean test run";
    "Verify with clean test run" -> "All tests pass, no pollution";

    // Example code
    subgraph cluster_code {
        label="EXAMPLE: Adding Stack Trace";

        before [label="// Before\nawait execFileAsync('git', ['init'], { cwd: projectDir });", shape=plaintext];

        after [label="// After\nconst stack = new Error().stack;\nconsole.error('🔍 GIT INIT:', { projectDir, cwd: process.cwd(), stack });\nawait execFileAsync('git', ['init'], { cwd: projectDir });", shape=plaintext];

        before -> after [label="add logging"];
    }

    // Common mistakes
    "AVOID: Using logger in tests" [shape=octagon, style=filled, fillcolor=orange, fontcolor=white];
    "AVOID: Logging after the operation" [shape=octagon, style=filled, fillcolor=orange, fontcolor=white];
    "AVOID: Not capturing process.cwd()" [shape=octagon, style=filled, fillcolor=orange, fontcolor=white];
}
```

**When to use:** Something is being initialized with the wrong value (path, config, etc.) but you can't tell which code is doing it.

**Key insight:** Stack traces show the exact call chain from test → your code.

**Critical:** Use `console.error()` not `logger` - logger may not appear in test output.

**Pattern:** Add stack capture BEFORE the operation, log the context (path, cwd, etc.) along with stack.
