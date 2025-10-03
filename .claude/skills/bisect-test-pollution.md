```dot
digraph BISECT_TEST_POLLUTION {
    label="Finding Which Test Creates Unwanted Files/State";

    // Entry
    "Start: Unwanted file appears during tests" [shape=doublecircle];

    // Initial check
    "Does file appear in full suite?" [shape=diamond];
    "Run full test suite and check" [shape=box];
    "npm test && ls -la unwanted-file" [shape=plaintext];

    // Create bisection script
    "File appears?" [shape=diamond];
    "Create bisection script" [shape=box];

    subgraph cluster_script {
        label="BISECTION SCRIPT STRUCTURE";

        script1 [label="#!/bin/bash", shape=plaintext];
        script2 [label="for test in $(find src -name '*.test.ts' | sort); do", shape=plaintext];
        script3 [label="  [ -e unwanted ] && continue  # Skip if already exists", shape=plaintext];
        script4 [label="  npm test $test > /dev/null 2>&1", shape=plaintext];
        script5 [label="  if [ -e unwanted ]; then", shape=plaintext];
        script6 [label="    echo \"FOUND: $test\"", shape=plaintext];
        script7 [label="    ls -la unwanted  # Show for inspection", shape=plaintext];
        script8 [label="    exit 1  # Stop at first polluter", shape=plaintext];
        script9 [label="  fi", shape=plaintext];
        script10 [label="done", shape=plaintext];

        script1 -> script2 -> script3 -> script4 -> script5 -> script6 -> script7 -> script8 -> script9 -> script10;
    }

    // Run bisection
    "Run bisection script" [shape=box];
    "./find-polluter.sh" [shape=plaintext];

    // Script output
    "Script found first polluter?" [shape=diamond];
    "Inspect what was created" [shape=box];
    "Check file contents/metadata" [shape=box];
    "ls -la; cat file; git log (if .git)" [shape=plaintext];

    // Understand WHY
    "Add stack trace to creation code" [shape=box];
    "Run just the polluter test" [shape=box];
    "See stack trace showing call chain" [shape=box];

    // Root cause
    "Identify root cause" [shape=box];
    "Examples: wrong path, missing cleanup, timing issue" [shape=ellipse];

    // Fix
    "Apply targeted fix" [shape=box];
    "Verify fix" [shape=box];
    "rm unwanted-file && ./find-polluter.sh" [shape=plaintext];

    // Success
    "No polluter found" [shape=doublecircle];
    "All tests clean" [shape=ellipse];

    // Flow
    "Start: Unwanted file appears during tests" -> "Does file appear in full suite?";
    "Does file appear in full suite?" -> "Run full test suite and check";
    "Run full test suite and check" -> "npm test && ls -la unwanted-file";
    "npm test && ls -la unwanted-file" -> "File appears?";

    "File appears?" -> "Create bisection script" [label="yes"];
    "File appears?" -> "Check individual test" [label="no, only in suite"];

    "Create bisection script" -> "Run bisection script";
    "Run bisection script" -> "./find-polluter.sh";
    "./find-polluter.sh" -> "Script found first polluter?";

    "Script found first polluter?" -> "Inspect what was created" [label="yes"];
    "Inspect what was created" -> "Check file contents/metadata";
    "Check file contents/metadata" -> "ls -la; cat file; git log (if .git)";

    "ls -la; cat file; git log (if .git)" -> "Add stack trace to creation code";
    "Add stack trace to creation code" -> "Run just the polluter test";
    "Run just the polluter test" -> "See stack trace showing call chain";

    "See stack trace showing call chain" -> "Identify root cause";
    "Identify root cause" -> "Examples: wrong path, missing cleanup, timing issue";
    "Examples: wrong path, missing cleanup, timing issue" -> "Apply targeted fix";

    "Apply targeted fix" -> "Verify fix";
    "Verify fix" -> "rm unwanted-file && ./find-polluter.sh";
    "rm unwanted-file && ./find-polluter.sh" -> "No polluter found";
    "No polluter found" -> "All tests clean";

    // Key insights
    "INSIGHT: Stop at FIRST polluter" [shape=octagon, style=filled, fillcolor=yellow];
    "INSIGHT: Leave file for inspection" [shape=octagon, style=filled, fillcolor=yellow];
    "INSIGHT: Run tests alphabetically" [shape=octagon, style=filled, fillcolor=yellow];

    "./find-polluter.sh" -> "INSIGHT: Stop at FIRST polluter" [style=dotted];
    "Inspect what was created" -> "INSIGHT: Leave file for inspection" [style=dotted];
    "for test in $(find src -name '*.test.ts' | sort); do" -> "INSIGHT: Run tests alphabetically" [style=dotted];

    // Why this works
    subgraph cluster_why {
        label="WHY THIS TECHNIQUE WORKS";

        why1 [label="First polluter is the ROOT cause", shape=box];
        why2 [label="Later tests may just propagate pollution", shape=box];
        why3 [label="Stopping early gives clean error state", shape=box];
        why4 [label="File left behind for forensic analysis", shape=box];

        why1 -> why2 -> why3 -> why4;
    }

    // Common mistakes
    "AVOID: Running all tests then checking" [shape=octagon, style=filled, fillcolor=orange, fontcolor=white];
    "AVOID: Cleaning up pollution in script" [shape=octagon, style=filled, fillcolor=orange, fontcolor=white];
    "AVOID: Continuing after finding polluter" [shape=octagon, style=filled, fillcolor=orange, fontcolor=white];
}
```

**When to use:** Tests create unwanted files/state but you don't know which test.

**Technique:** Linear bisection - run tests alphabetically, stop at first pollution.

**Critical:** STOP at first polluter and leave pollution for inspection.

**Why:** First polluter is the root cause. Later tests may just propagate existing pollution.

**This session:** Found `agent.test.ts` created `.git` in `packages/core` by running tests one-by-one until `.git` appeared.

**Script template:** Loop through tests, check before/after each, exit on first detection.
