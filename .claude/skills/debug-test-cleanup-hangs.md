```dot
digraph DEBUG_TEST_CLEANUP_HANGS {
    label="Systematic Approach to Debugging Hanging Test Cleanup";

    // Entry
    "Start: Tests timeout in afterEach/cleanup" [shape=doublecircle];

    // Symptom identification
    "Error says 'Hook timed out'?" [shape=diamond];
    "Error in beforeEach or afterEach?" [shape=diamond];

    // Check what's running
    "Check for hanging processes" [shape=box];
    "ps auxwww | grep -i 'git\\|vitest\\|node'" [shape=plaintext];

    // Common causes
    "What's hanging?" [shape=diamond];

    // Cause 1: File handles
    "File handles still open" [shape=ellipse];
    "Check: Database connections" [shape=box];
    "Check: Log files" [shape=box];
    "Fix: Close DB before cleanup" [shape=box];
    "resetPersistence() in afterEach" [shape=plaintext];

    // Cause 2: Child processes
    "Child processes not terminating" [shape=ellipse];
    "Check: Git operations" [shape=box];
    "Check: Container processes" [shape=box];
    "Fix: Add timeouts to operations" [shape=box];
    "git worktree remove --force" [shape=plaintext];
    "Promise.race with timeout" [shape=plaintext];

    // Cause 3: Cleanup operations hanging
    "Cleanup operations hanging" [shape=ellipse];
    "Check: What cleanup does" [shape=box];
    "Check: Temp dir removal" [shape=box];
    "Check: Resource cleanup loops" [shape=box];

    // Fix strategies
    "Add timeout to cleanup" [shape=box];
    "afterEach(async () => { ... }, 10000)" [shape=plaintext];

    "Add retries to file operations" [shape=box];
    "fs.rm(dir, { maxRetries: 3, retryDelay: 100 })" [shape=plaintext];

    "Use Promise.race for cleanup" [shape=box];
    "Promise.race([cleanup(), timeout(5000)])" [shape=plaintext];

    "Catch and log, don't throw" [shape=box];
    "try { cleanup() } catch (e) { console.warn(e) }" [shape=plaintext];

    // Order matters
    "CRITICAL: Cleanup order matters" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];

    subgraph cluster_cleanup_order {
        label="CORRECT CLEANUP ORDER";

        order1 [label="1. Close database connections", shape=box];
        order2 [label="2. Stop running processes", shape=box];
        order3 [label="3. Clean up resources (containers, etc)", shape=box];
        order4 [label="4. Remove temp directories", shape=box];

        order1 -> order2 -> order3 -> order4;

        wrong [label="❌ WRONG: Delete temp dir while DB still open\nResult: ENOTEMPTY errors", shape=octagon, style=filled, fillcolor=orange];
    }

    // Debugging technique
    "Can't figure out what's hanging?" [shape=diamond];
    "Add console.error in cleanup" [shape=box];
    "Log each cleanup step" [shape=box];
    "console.error('Cleanup step 1')" [shape=plaintext];
    "console.error('Cleanup step 2')" [shape=plaintext];
    "Where does output stop?" [shape=box];
    "That step is hanging" [shape=ellipse];

    // Success
    "Tests complete quickly, no timeouts" [shape=doublecircle];

    // Flow
    "Start: Tests timeout in afterEach/cleanup" -> "Error says 'Hook timed out'?";
    "Error says 'Hook timed out'?" -> "Error in beforeEach or afterEach?" [label="yes"];
    "Error in beforeEach or afterEach?" -> "Check for hanging processes" [label="afterEach"];

    "Check for hanging processes" -> "ps auxwww | grep -i 'git\\|vitest\\|node'";
    "ps auxwww | grep -i 'git\\|vitest\\|node'" -> "What's hanging?";

    "What's hanging?" -> "File handles still open" [label="DB, files"];
    "What's hanging?" -> "Child processes not terminating" [label="git, containers"];
    "What's hanging?" -> "Cleanup operations hanging" [label="temp dir removal"];

    "File handles still open" -> "Check: Database connections";
    "Check: Database connections" -> "Fix: Close DB before cleanup";
    "Fix: Close DB before cleanup" -> "resetPersistence() in afterEach";

    "Child processes not terminating" -> "Check: Git operations";
    "Check: Git operations" -> "Fix: Add timeouts to operations";
    "Fix: Add timeouts to operations" -> "git worktree remove --force";
    "git worktree remove --force" -> "Promise.race with timeout";

    "Cleanup operations hanging" -> "Check: What cleanup does";
    "Check: What cleanup does" -> "Check: Temp dir removal";
    "Check: Temp dir removal" -> "Check: Resource cleanup loops";

    "Check: Resource cleanup loops" -> "Add timeout to cleanup";
    "Add timeout to cleanup" -> "afterEach(async () => { ... }, 10000)";
    "afterEach(async () => { ... }, 10000)" -> "Add retries to file operations";
    "Add retries to file operations" -> "fs.rm(dir, { maxRetries: 3, retryDelay: 100 })";
    "fs.rm(dir, { maxRetries: 3, retryDelay: 100 })" -> "Use Promise.race for cleanup";
    "Use Promise.race for cleanup" -> "Promise.race([cleanup(), timeout(5000)])";
    "Promise.race([cleanup(), timeout(5000)])" -> "Catch and log, don't throw";
    "Catch and log, don't throw" -> "try { cleanup() } catch (e) { console.warn(e) }";

    "try { cleanup() } catch (e) { console.warn(e) }" -> "CRITICAL: Cleanup order matters";
    "CRITICAL: Cleanup order matters" -> "Tests complete quickly, no timeouts";

    "Can't figure out what's hanging?" -> "Add console.error in cleanup";
    "Add console.error in cleanup" -> "Log each cleanup step";
    "Log each cleanup step" -> "console.error('Cleanup step 1')";
    "console.error('Cleanup step 1')" -> "console.error('Cleanup step 2')";
    "console.error('Cleanup step 2')" -> "Where does output stop?";
    "Where does output stop?" -> "That step is hanging";

    // Key insights
    "INSIGHT: Close DB before removing directories" [shape=octagon, style=filled, fillcolor=yellow];
    "INSIGHT: Use sync AND async removal (fallback)" [shape=octagon, style=filled, fillcolor=yellow];
    "INSIGHT: Never throw in cleanup - log and continue" [shape=octagon, style=filled, fillcolor=yellow];

    "CRITICAL: Cleanup order matters" -> "INSIGHT: Close DB before removing directories" [style=dotted];
    "Add retries to file operations" -> "INSIGHT: Use sync AND async removal (fallback)" [style=dotted];
    "Catch and log, don't throw" -> "INSIGHT: Never throw in cleanup - log and continue" [style=dotted];
}
```

**When to use:** Tests are timing out in cleanup hooks, preventing test completion.

**Root causes:** File handles, child processes, or cleanup operations hanging.

**Key techniques:**
1. **Cleanup order matters:** DB first, processes second, resources third, directories last
2. **Add timeouts everywhere:** afterEach timeout, Promise.race, command timeouts
3. **Fallback strategies:** Try async rm, fall back to sync rmSync
4. **Never throw in cleanup:** Log warnings, continue best-effort

**Debugging:** Add console.error at each cleanup step to find where it hangs.
