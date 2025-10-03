```dot
digraph FIND_PARAMETER_ORDER_BUGS {
    label="Finding and Fixing Wrong Parameter Order in Function Calls";

    // Entry
    "Start: Strange values appearing in unexpected places" [shape=doublecircle];

    // Symptoms
    "Symptoms" [shape=ellipse];
    "Description string used as file path" [shape=ellipse];
    "Path used as description" [shape=ellipse];
    "Configuration object in wrong parameter" [shape=ellipse];

    // Recognition
    "See descriptions in error messages about paths?" [shape=diamond];
    "Example: 'Project for testing' as projectDir" [shape=ellipse];

    // Investigation
    "Check function signature" [shape=box];
    "Read function definition carefully" [shape=box];
    "function create(name, path, description)" [shape=plaintext];

    // Search for calls
    "Search for all calls to function" [shape=box];
    "grep -rn 'FunctionName.create' src --include='*.ts'" [shape=plaintext];

    // Pattern detection
    "Look for suspicious patterns" [shape=box];

    subgraph cluster_patterns {
        label="SUSPICIOUS PATTERNS";

        pattern1 [label="Strings that look like descriptions in path position", shape=ellipse];
        pattern2 [label="Paths in description position", shape=ellipse];
        pattern3 [label="tempDir in 3rd position when should be 2nd", shape=ellipse];
        pattern4 [label="Multiple parameters of same type (easy to swap)", shape=ellipse];

        pattern1 -> pattern2 -> pattern3 -> pattern4;
    }

    // Use grep to find specific patterns
    "Search for misplaced descriptions" [shape=box];
    "grep 'create.*\".*for.*\".*tempDir' src" [shape=plaintext];

    "Search for hardcoded paths" [shape=box];
    "grep 'create.*\"/test/' src" [shape=plaintext];

    // Found issues
    "Found calls with wrong order?" [shape=diamond];
    "Count how many" [shape=box];

    // Fix strategy
    "Many to fix?" [shape=diamond];

    // Few: Manual fix
    "Manual fix each one" [shape=box];
    "Read signature carefully" [shape=box];
    "Reorder parameters to match" [shape=box];

    // Many: Use sed
    "Use sed for bulk fix" [shape=box];
    "sed -i 's/pattern/replacement/g' file" [shape=plaintext];

    // Validation
    "CRITICAL: Verify sed didn't break code" [shape=octagon, style=filled, fillcolor=red, fontcolor=white];
    "Run tests after sed" [shape=box];
    "npm test" [shape=plaintext];
    "Review diff carefully" [shape=box];
    "git diff" [shape=plaintext];

    // Prevention
    "How to prevent in future?" [shape=diamond];

    "Add type safety" [shape=box];
    "Use distinct types for parameters" [shape=box];
    "type Name = string & { __brand: 'Name' }" [shape=plaintext];
    "type Path = string & { __brand: 'Path' }" [shape=plaintext];

    "Add validation" [shape=box];
    "Check parameter makes sense" [shape=box];
    "if (description.includes('/')) throw" [shape=plaintext];
    "if (!existsSync(path)) throw" [shape=plaintext];

    // Success
    "All calls use correct order" [shape=doublecircle];

    // Flow
    "Start: Strange values appearing in unexpected places" -> "Symptoms";
    "Symptoms" -> "Description string used as file path";
    "Symptoms" -> "Path used as description";
    "Symptoms" -> "Configuration object in wrong parameter";

    "Configuration object in wrong parameter" -> "See descriptions in error messages about paths?";
    "See descriptions in error messages about paths?" -> "Example: 'Project for testing' as projectDir" [label="yes"];

    "Example: 'Project for testing' as projectDir" -> "Check function signature";
    "Check function signature" -> "Read function definition carefully";
    "Read function definition carefully" -> "function create(name, path, description)";

    "function create(name, path, description)" -> "Search for all calls to function";
    "Search for all calls to function" -> "grep -rn 'FunctionName.create' src --include='*.ts'";

    "grep -rn 'FunctionName.create' src --include='*.ts'" -> "Look for suspicious patterns";
    "Look for suspicious patterns" -> "Search for misplaced descriptions";
    "Search for misplaced descriptions" -> "grep 'create.*\".*for.*\".*tempDir' src";

    "Look for suspicious patterns" -> "Search for hardcoded paths";
    "Search for hardcoded paths" -> "grep 'create.*\"/test/' src";

    "grep 'create.*\"/test/' src" -> "Found calls with wrong order?";
    "Found calls with wrong order?" -> "Count how many" [label="yes"];

    "Count how many" -> "Many to fix?";
    "Many to fix?" -> "Manual fix each one" [label="< 10"];
    "Many to fix?" -> "Use sed for bulk fix" [label="> 10"];

    "Manual fix each one" -> "Read signature carefully";
    "Read signature carefully" -> "Reorder parameters to match";

    "Use sed for bulk fix" -> "sed -i 's/pattern/replacement/g' file";
    "sed -i 's/pattern/replacement/g' file" -> "CRITICAL: Verify sed didn't break code";

    "CRITICAL: Verify sed didn't break code" -> "Run tests after sed";
    "Run tests after sed" -> "npm test";
    "npm test" -> "Review diff carefully";
    "Review diff carefully" -> "git diff";

    "Reorder parameters to match" -> "How to prevent in future?";
    "git diff" -> "How to prevent in future?";

    "How to prevent in future?" -> "Add type safety" [label="best"];
    "How to prevent in future?" -> "Add validation" [label="also"];

    "Add type safety" -> "Use distinct types for parameters";
    "Use distinct types for parameters" -> "type Name = string & { __brand: 'Name' }";
    "type Name = string & { __brand: 'Name' }" -> "type Path = string & { __brand: 'Path' }";

    "Add validation" -> "Check parameter makes sense";
    "Check parameter makes sense" -> "if (description.includes('/')) throw";
    "if (description.includes('/')) throw" -> "if (!existsSync(path)) throw";

    "type Path = string & { __brand: 'Path' }" -> "All calls use correct order";
    "if (!existsSync(path)) throw" -> "All calls use correct order";

    // Example from this session
    subgraph cluster_example {
        label="EXAMPLE FROM THIS SESSION";

        ex_symptom [label="'Project for abort testing' appeared as projectDir", shape=ellipse];
        ex_sig [label="Signature: create(name, workingDir, description, config)", shape=plaintext];
        ex_wrong [label="Wrong: create(name, description, workingDir, config)", shape=plaintext];
        ex_search [label="grep 'Project.create.*for.*tempDir' src", shape=plaintext];
        ex_found [label="Found 4 tests with wrong order", shape=ellipse];
        ex_fix [label="Fixed parameter order in each", shape=box];

        ex_symptom -> ex_sig -> ex_wrong -> ex_search -> ex_found -> ex_fix;
    }

    // Prevention technique
    "PREVENTION: Validate parameters make sense" [shape=octagon, style=filled, fillcolor=green, fontcolor=white];
    "if (workingDir.startsWith('Project for')) throw new Error('Wrong parameter order')" [shape=plaintext];

    "All calls use correct order" -> "PREVENTION: Validate parameters make sense" [style=dotted];
}
```

**When to use:** Seeing strange values where they don't belong - descriptions in path fields, paths in description fields, etc.

**Root cause:** Functions with multiple string parameters are easy to swap accidentally.

**Detection:** Grep for patterns like descriptions containing "for testing" in path positions.

**Fix:**
- < 10 calls: Manual fix
- \> 10 calls: Use sed (but verify carefully!)

**Prevention:**
- Use distinct types (branded strings)
- Validate parameters make sense (e.g., paths should exist, descriptions shouldn't start with `/`)

**This session:** Found 4 tests passing `(name, description, workingDir)` instead of `(name, workingDir, description)`.
