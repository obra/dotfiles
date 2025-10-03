```dot
digraph FIX_ZOMBIE_RESOURCE_ACCUMULATION {
    label="Preventing Zombie Resources from Accumulating During Tests";

    // Entry
    "Start: Resources accumulating (containers, processes, files)" [shape=doublecircle];

    // Symptoms
    "Symptoms" [shape=ellipse];
    "67+ zombie containers running" [shape=ellipse];
    "Hundreds of orphaned temp directories" [shape=ellipse];
    "System resources exhausted" [shape=ellipse];
    "Tests fail with 'no space' or 'too many open files'" [shape=ellipse];

    // Root cause analysis
    "Why are resources not cleaned up?" [shape=diamond];

    // Cause 1: Cleanup not running
    "Cause 1: Cleanup never runs" [shape=ellipse];
    "Tests timeout before afterEach" [shape=box];
    "afterEach hook times out itself" [shape=box];
    "Process killed before cleanup" [shape=box];

    // Cause 2: Cleanup fails silently
    "Cause 2: Cleanup fails silently" [shape=ellipse];
    "Errors caught and swallowed" [shape=box];
    "Resource in wrong state to clean" [shape=box];
    "Cleanup assumes success without checking" [shape=box];

    // Cause 3: Tests use wrong default
    "Cause 3: Wrong default mode" [shape=ellipse];
    "Tests default to expensive mode" [shape=box];
    "Example: container vs worktree" [shape=box];
    "All tests use containers even when not needed" [shape=box];

    // Immediate triage
    "FIRST: Stop the bleeding" [shape=box];
    "Manually clean up existing zombies" [shape=box];
    "container list | xargs container rm -f" [shape=plaintext];
    "rm -rf /tmp/test-*" [shape=plaintext];

    // Fix strategy
    "Choose fix strategy" [shape=diamond];

    // Strategy 1: Change defaults
    "Strategy 1: Change to cheaper default" [shape=box];
    "Default to worktree not container" [shape=box];
    "Default to in-memory not persistent" [shape=box];
    "Explicit opt-in for expensive resources" [shape=box];

    // Strategy 2: Improve cleanup
    "Strategy 2: Make cleanup more robust" [shape=box];
    "Add timeouts to all cleanup operations" [shape=box];
    "Use Promise.race for cleanup" [shape=box];
    "Catch errors, log, continue" [shape=box];
    "Add platform guards (skip on unsupported)" [shape=box];

    // Strategy 3: Track resources
    "Strategy 3: Track resources explicitly" [shape=box];
    "Register resource when created" [shape=box];
    "createdContainers.push(id)" [shape=plaintext];
    "Clean up tracked resources in afterEach" [shape=box];
    "for (const id of created) { cleanup(id) }" [shape=plaintext];

    // Validation
    "Test the fix" [shape=box];
    "Run full suite multiple times" [shape=box];
    "Check resource count before/after" [shape=box];
    "container list | wc -l" [shape=plaintext];

    // Success criteria
    "Resources stay constant?" [shape=diamond];
    "Monitor over multiple runs" [shape=box];
    "Count should be 0 or small constant" [shape=ellipse];

    // Success
    "No accumulation, tests clean up properly" [shape=doublecircle];

    // Flow
    "Start: Resources accumulating (containers, processes, files)" -> "Symptoms";
    "Symptoms" -> "67+ zombie containers running";
    "Symptoms" -> "Hundreds of orphaned temp directories";
    "Symptoms" -> "System resources exhausted";
    "Symptoms" -> "Tests fail with 'no space' or 'too many open files'";

    "Tests fail with 'no space' or 'too many open files'" -> "Why are resources not cleaned up?";

    "Why are resources not cleaned up?" -> "Cause 1: Cleanup never runs" [label="timing"];
    "Why are resources not cleaned up?" -> "Cause 2: Cleanup fails silently" [label="errors"];
    "Why are resources not cleaned up?" -> "Cause 3: Wrong default mode" [label="defaults"];

    "Cause 1: Cleanup never runs" -> "Tests timeout before afterEach";
    "Tests timeout before afterEach" -> "afterEach hook times out itself";
    "afterEach hook times out itself" -> "Process killed before cleanup";

    "Cause 2: Cleanup fails silently" -> "Errors caught and swallowed";
    "Errors caught and swallowed" -> "Resource in wrong state to clean";
    "Resource in wrong state to clean" -> "Cleanup assumes success without checking";

    "Cause 3: Wrong default mode" -> "Tests default to expensive mode";
    "Tests default to expensive mode" -> "Example: container vs worktree";
    "Example: container vs worktree" -> "All tests use containers even when not needed";

    "All tests use containers even when not needed" -> "FIRST: Stop the bleeding";
    "FIRST: Stop the bleeding" -> "Manually clean up existing zombies";
    "Manually clean up existing zombies" -> "container list | xargs container rm -f";
    "container list | xargs container rm -f" -> "rm -rf /tmp/test-*";

    "rm -rf /tmp/test-*" -> "Choose fix strategy";

    "Choose fix strategy" -> "Strategy 1: Change to cheaper default" [label="best: prevent creation"];
    "Choose fix strategy" -> "Strategy 2: Make cleanup more robust" [label="and/or"];
    "Choose fix strategy" -> "Strategy 3: Track resources explicitly" [label="and/or"];

    "Strategy 1: Change to cheaper default" -> "Default to worktree not container";
    "Default to worktree not container" -> "Default to in-memory not persistent";
    "Default to in-memory not persistent" -> "Explicit opt-in for expensive resources";

    "Strategy 2: Make cleanup more robust" -> "Add timeouts to all cleanup operations";
    "Add timeouts to all cleanup operations" -> "Use Promise.race for cleanup";
    "Use Promise.race for cleanup" -> "Catch errors, log, continue";
    "Catch errors, log, continue" -> "Add platform guards (skip on unsupported)";

    "Strategy 3: Track resources explicitly" -> "Register resource when created";
    "Register resource when created" -> "createdContainers.push(id)";
    "createdContainers.push(id)" -> "Clean up tracked resources in afterEach";
    "Clean up tracked resources in afterEach" -> "for (const id of created) { cleanup(id) }";

    "Explicit opt-in for expensive resources" -> "Test the fix";
    "Add platform guards (skip on unsupported)" -> "Test the fix";
    "for (const id of created) { cleanup(id) }" -> "Test the fix";

    "Test the fix" -> "Run full suite multiple times";
    "Run full suite multiple times" -> "Check resource count before/after";
    "Check resource count before/after" -> "container list | wc -l";
    "container list | wc -l" -> "Resources stay constant?";

    "Resources stay constant?" -> "Monitor over multiple runs" [label="yes"];
    "Monitor over multiple runs" -> "Count should be 0 or small constant";
    "Count should be 0 or small constant" -> "No accumulation, tests clean up properly";

    "Resources stay constant?" -> "FIRST: Stop the bleeding" [label="no, still accumulating"];

    // Key insights
    subgraph cluster_insights {
        label="KEY INSIGHTS";

        insight1 [label="Cheaper default = less cleanup needed", shape=box];
        insight2 [label="Cleanup WILL fail sometimes - handle gracefully", shape=box];
        insight3 [label="Track explicitly if implicit cleanup unreliable", shape=box];
        insight4 [label="Platform-specific resources need platform guards", shape=box];
    }

    // Example: This session
    subgraph cluster_example {
        label="EXAMPLE FROM THIS SESSION";

        ex_problem [label="67 zombie containers\nTests defaulting to container mode\nCleanup hanging", shape=ellipse];

        ex_fix1 [label="Changed default to worktree", shape=box];
        ex_fix2 [label="Added 3s timeout to workspace cleanup", shape=box];
        ex_fix3 [label="Close DB before cleanup", shape=box];
        ex_fix4 [label="Added skipIf(platform !== 'darwin')", shape=box];

        ex_result [label="Result: 0 containers after tests", shape=doublecircle];

        ex_problem -> ex_fix1 -> ex_fix2 -> ex_fix3 -> ex_fix4 -> ex_result;
    }
}
```

**When to use:** Test runs leave behind zombie processes, containers, temp directories, or other resources.

**Immediate action:** Manually clean up existing zombies before debugging.

**Three-pronged fix:**
1. **Change defaults** to cheaper resources (best: prevent problem)
2. **Improve cleanup** with timeouts and error handling
3. **Track explicitly** if implicit cleanup unreliable

**This session:** Changed default from container to worktree, preventing 67+ zombie containers.
