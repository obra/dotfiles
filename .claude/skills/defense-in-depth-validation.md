```dot
digraph DEFENSE_IN_DEPTH_VALIDATION {
    label="Layered Validation to Catch Bugs at Multiple Points";

    // Entry
    "Start: Found a bug where bad value causes problems" [shape=doublecircle];

    // Example
    "Example: empty string projectDir causes git init in cwd" [shape=ellipse];

    // Analysis
    "Trace the bug backwards" [shape=box];
    "Where did bad value come from?" [shape=diamond];
    "Where is it first used?" [shape=diamond];
    "Where could we validate it?" [shape=diamond];

    // Identify validation points
    "Map the data flow" [shape=box];
    "List ALL points where value passes through" [shape=box];

    // Example flow
    subgraph cluster_example_flow {
        label="EXAMPLE: projectDir validation points";

        point1 [label="Point 1:\nProject.create(name, dir, ...)", shape=box];
        point2 [label="Point 2:\nSession uses project.getWorkingDirectory()", shape=box];
        point3 [label="Point 3:\nWorkspaceManager.createWorkspace(dir, ...)", shape=box];
        point4 [label="Point 4:\nWorktreeManager creates worktree in dir", shape=box];
        point5 [label="Point 5:\ngit init runs", shape=box];

        point1 -> point2 -> point3 -> point4 -> point5;
    }

    // Add validation at EACH point
    "Add validation at EACH point" [shape=box];

    // Layer 1
    "Layer 1: At entry point" [shape=box];
    "if (!dir || dir.trim() === '') throw" [shape=plaintext];
    "if (!existsSync(dir)) throw" [shape=plaintext];

    // Layer 2
    "Layer 2: At intermediate steps" [shape=box];
    "if (!dir) throw Error('dir required')" [shape=plaintext];

    // Layer 3
    "Layer 3: At dangerous operation" [shape=box];
    "if (NODE_ENV==='test' && !dir.includes('/tmp/')) throw" [shape=plaintext];

    // Layer 4
    "Layer 4: At final action" [shape=box];
    "Log stack trace before git init" [shape=plaintext];

    // Why multiple layers?
    "Why not just one check?" [shape=diamond];

    "Defense in depth prevents" [shape=box];
    "Different code paths bypassing single check" [shape=ellipse];
    "Edge cases not caught by simple validation" [shape=ellipse];
    "Refactoring breaking validation" [shape=ellipse];
    "Tests with mocks/stubs bypassing checks" [shape=ellipse];

    // Each layer catches different cases
    "Each layer has different purpose" [shape=box];

    subgraph cluster_layer_purposes {
        label="LAYER PURPOSES";

        purpose1 [label="Entry validation:\nReject obviously invalid input", shape=box];
        purpose2 [label="Business logic validation:\nEnsure data makes sense", shape=box];
        purpose3 [label="Environment-specific guards:\nPrevent dangerous ops in tests", shape=box];
        purpose4 [label="Debugging aids:\nCapture context when problem occurs", shape=box];

        purpose1 -> purpose2 -> purpose3 -> purpose4;
    }

    // Testing the layers
    "Test each layer independently" [shape=box];
    "Try to bypass layer 1" [shape=box];
    "Does layer 2 catch it?" [shape=diamond];
    "Try to bypass layer 2" [shape=box];
    "Does layer 3 catch it?" [shape=diamond];

    // Success criteria
    "Bug impossible to reproduce" [shape=doublecircle];
    "Clear error at FIRST validation layer hit" [shape=ellipse];

    // Flow
    "Start: Found a bug where bad value causes problems" -> "Example: empty string projectDir causes git init in cwd";
    "Example: empty string projectDir causes git init in cwd" -> "Trace the bug backwards";

    "Trace the bug backwards" -> "Where did bad value come from?";
    "Where did bad value come from?" -> "Where is it first used?";
    "Where is it first used?" -> "Where could we validate it?";
    "Where could we validate it?" -> "Map the data flow";

    "Map the data flow" -> "List ALL points where value passes through";
    "List ALL points where value passes through" -> "Add validation at EACH point";

    "Add validation at EACH point" -> "Layer 1: At entry point";
    "Layer 1: At entry point" -> "if (!dir || dir.trim() === '') throw";
    "if (!dir || dir.trim() === '') throw" -> "if (!existsSync(dir)) throw";

    "Add validation at EACH point" -> "Layer 2: At intermediate steps";
    "Layer 2: At intermediate steps" -> "if (!dir) throw Error('dir required')";

    "Add validation at EACH point" -> "Layer 3: At dangerous operation";
    "Layer 3: At dangerous operation" -> "if (NODE_ENV==='test' && !dir.includes('/tmp/')) throw";

    "Add validation at EACH point" -> "Layer 4: At final action";
    "Layer 4: At final action" -> "Log stack trace before git init";

    "if (!existsSync(dir)) throw" -> "Why not just one check?";
    "Why not just one check?" -> "Defense in depth prevents";
    "Defense in depth prevents" -> "Different code paths bypassing single check";
    "Defense in depth prevents" -> "Edge cases not caught by simple validation";
    "Defense in depth prevents" -> "Refactoring breaking validation";
    "Defense in depth prevents" -> "Tests with mocks/stubs bypassing checks";

    "Tests with mocks/stubs bypassing checks" -> "Each layer has different purpose";
    "Each layer has different purpose" -> "Test each layer independently";

    "Test each layer independently" -> "Try to bypass layer 1";
    "Try to bypass layer 1" -> "Does layer 2 catch it?";
    "Does layer 2 catch it?" -> "Try to bypass layer 2" [label="yes"];
    "Try to bypass layer 2" -> "Does layer 3 catch it?";
    "Does layer 3 catch it?" -> "Bug impossible to reproduce" [label="yes"];

    "Bug impossible to reproduce" -> "Clear error at FIRST validation layer hit";

    // Key principle
    "PRINCIPLE: Fail fast at the earliest validation point" [shape=octagon, style=filled, fillcolor=green, fontcolor=white];
}
```

**When to use:** Found a bug where invalid data causes problems deep in the call stack. Want to prevent it completely.

**Strategy:** Add validation at EVERY point the data passes through, not just one place.

**Why it works:**
- Different code paths may bypass any single check
- Each layer has a different purpose (entry, business logic, safety, debugging)
- If one layer is removed during refactoring, others still protect

**Example from this session:** Empty projectDir caught at 4 layers:
1. Project.create checks if empty
2. Project.create checks if exists
3. WorktreeManager checks if empty
4. WorktreeManager NODE_ENV guard checks if in /tmp/

All 4 layers were necessary - removing any one caused bugs to slip through.
