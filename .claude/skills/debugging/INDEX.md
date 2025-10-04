# Debugging Skills

Techniques for finding and fixing bugs systematically.

## Available Skills

- @defense-in-depth/SKILL.md - Validate at every layer data passes through to make bugs impossible. Use when invalid data causes problems deep in call stack.

- @root-cause-tracing/SKILL.md - Trace bugs backward through call stack to find original trigger. Use when bugs appear deep in execution and you need to find where they originate. Includes bisection script for finding test pollution.

- @systematic-debugging/SKILL.md - Four-phase debugging framework that ensures root cause investigation before attempting fixes. Use when encountering any technical issue, bug, or test failure. Especially critical when under time pressure or tempted to quick-fix.

- @verification-before-completion/SKILL.md - Never claim work is complete, tests pass, or bugs are fixed without running actual verification commands. Use before claiming complete, fixed, working, passing, clean, or ready. Before expressing satisfaction with your work. Before committing or creating PRs. When tempted to declare success.
