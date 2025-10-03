# Code Quality Checklist

## Scope
- **Smallest change possible?**
  - If no → Reduce scope further
  - Remove anything not strictly necessary

## Style
- **Matches existing style exactly?**
  - Check indentation (tabs vs spaces)
  - Check naming conventions
  - Check file organization
  - Consistency within file trumps external standards

## Duplication
- **Code duplication present?**
  - If yes → Extract common code (work hard at this)
  - Look for similar patterns across files
  - Don't settle for "good enough" - eliminate duplication

## Broken Code
- **See broken code while working?**
  - Fix it immediately
  - Don't ask permission for bug fixes
  - All broken windows are your responsibility

## Naming
- **Names tell WHAT not HOW?**
  - Good: `Tool`, `execute()`, `RemoteTool`
  - Bad: `AbstractToolInterface`, `executeToolWithValidation()`, `MCPToolWrapper`

- **Contains temporal/implementation words?**
  - Forbidden: New, Old, Legacy, Wrapper, Unified, Enhanced, Improved
  - Forbidden: Impl, Manager (unless truly managing), Handler (unless truly handling)
  - If you see these → Stop and rename for actual purpose

## File Header
- **Has ABOUTME comment?**
  - Every file needs 2-line comment at top
  - Format: `// ABOUTME: what this file does`
  - Each line starts with `ABOUTME:` for greppability

## Remember
- Quality is not optional
- These checks prevent technical debt
- Fix it right the first time
