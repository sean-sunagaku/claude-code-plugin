# Sub-Agent Types: Complete Reference

## Built-in Agent Types

### general-purpose

The most versatile agent type with full tool access.

**Tools:** Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, Task (nested), TaskCreate, TaskUpdate, TaskList, SendMessage, TeamCreate, TeamDelete, NotebookEdit, and all MCP tools

**Ideal for:**
- Feature implementation requiring file edits
- Multi-file refactoring
- Full-stack development tasks
- Any task needing write access to the filesystem
- Tasks requiring bash commands AND file edits

**Avoid when:**
- Task is read-only (use Explore instead - faster and cheaper)
- Task only needs terminal commands (use Bash instead)
- Task only needs a plan (use Plan instead)

**Tips:**
- Provide clear, complete prompts - the agent starts fresh with no prior context
- Specify the working directory and relevant file paths explicitly
- Include acceptance criteria so the agent knows when it's done

---

### Explore

Fast, read-only agent optimized for codebase exploration and research.

**Tools:** Glob, Grep, Read, WebFetch, WebSearch (NO Write, Edit, Bash, Task)

**Ideal for:**
- Finding files, functions, classes, or patterns
- Understanding code architecture
- Answering questions about the codebase
- Searching for usage patterns across many files
- Investigating bugs (finding root cause, not fixing)

**Thoroughness levels (specify in prompt):**
- `quick` - Basic searches, 1-2 queries
- `medium` - Moderate exploration, multiple search strategies
- `very thorough` - Comprehensive analysis across multiple locations and naming conventions

**Avoid when:**
- Any file modifications are needed
- Bash commands must be executed
- The search target is simple enough for a direct Glob/Grep call

**Tips:**
- Specify thoroughness level in the prompt
- More efficient than general-purpose for pure research
- Returns structured findings that can inform subsequent implementation agents

---

### Plan

Architecture and design specialist for creating implementation plans.

**Tools:** Glob, Grep, Read, WebFetch, WebSearch (NO Write, Edit, Bash, Task)

**Ideal for:**
- Designing implementation strategies
- Identifying critical files and architectural trade-offs
- Creating step-by-step plans before implementation
- Evaluating multiple approaches to a problem
- Technical design documents

**Avoid when:**
- Implementation is straightforward and doesn't need planning
- The plan has already been created

**Tips:**
- Feed the plan output to a general-purpose agent for implementation
- Useful as the first phase in a research-then-implement pattern

---

### Bash

Command execution specialist with minimal overhead.

**Tools:** Bash only

**Ideal for:**
- Git operations (status, diff, log, branch management)
- Running test suites
- Build commands (npm, cargo, make, etc.)
- Docker operations
- System administration tasks
- Any pure CLI task

**Avoid when:**
- File reading/searching is needed (use Explore)
- File editing is needed (use general-purpose)

**Tips:**
- Fastest agent type for terminal-only tasks
- Perfect for background tasks like running test suites
- Use `run_in_background: true` for long-running commands

---

### code-simplifier

Specialized for code cleanup, refactoring, and maintainability improvements.

**Tools:** All tools (same as general-purpose)

**Ideal for:**
- Simplifying complex or verbose code
- Improving code clarity and consistency
- Refactoring for maintainability
- Removing dead code or redundancy
- Standardizing patterns across files

**Avoid when:**
- Adding new features (use general-purpose)
- The task isn't about code quality

**Tips:**
- Focuses on recently modified code unless instructed otherwise
- Preserves all functionality while simplifying
- Good as the final stage in a development pipeline

---

### claude-code-guide

Documentation and guidance specialist for Claude Code itself.

**Tools:** Glob, Grep, Read, WebFetch, WebSearch

**Ideal for:**
- Questions about Claude Code features, hooks, slash commands
- Claude Agent SDK usage
- Claude API / Anthropic SDK questions
- IDE integration guidance

**Avoid when:**
- The task isn't about Claude Code or the Anthropic API

---

### statusline-setup

Configures Claude Code's status line display.

**Tools:** Read, Edit

**Ideal for:**
- Customizing the status line display
- Setting up status indicators

---

## Project Custom Agents (`.claude/agents/`)

Custom agents defined in the project's `.claude/agents/` directory. These agents have project-specific context (coding conventions, file structure, reference files) pre-loaded in their system prompt. **Prefer these over `general-purpose` when the task falls within their domain.**

### backend-dev

Backend implementation specialist for `packages/server/`.

**Pre-loaded context:** Hono framework patterns, Drizzle ORM + SQLite, Zod validation, SSE streaming with `streamSSE()`, ESM import conventions (`.js` extension), Vitest test patterns

**Scope:** `packages/server/` only - will not touch other packages

**Ideal for:**
- New API route implementation
- Database schema changes and queries
- Server-side business logic
- Backend bug fixes

**Reference files the agent knows:**
- `packages/server/src/routes/brainstorm.ts` (route pattern)
- `packages/server/src/db/schema.ts` (DB schema)
- `packages/server/src/lib/ai-provider/index.ts` (AI service)

---

### frontend-dev

Frontend implementation specialist for `packages/web/`.

**Pre-loaded context:** Next.js 16 App Router, React 19, Tailwind CSS, next-intl i18n, lucide-react icons, react-markdown rendering, SSE via `response.body.getReader()`, `'use client'` directive rules

**Scope:** `packages/web/` only - will not touch other packages

**Ideal for:**
- New page/component implementation
- UI/UX changes and styling
- Client-side state management with hooks
- Frontend bug fixes

**Reference files the agent knows:**
- `packages/web/components/brainstorm/brainstorm-chat.tsx` (large component)
- `packages/web/hooks/use-brainstorm.ts` (SSE + state hook)
- `packages/web/components/ui/button.tsx` (UI component)
- `packages/web/components/chat/markdown-components.tsx` (markdown rendering)

---

### tester

Test design and implementation specialist.

**Pre-loaded context:** Vitest runner, `vi.mock()` patterns for DB/AI service mocking, test file organization under `src/__tests__/`, Japanese test names OK, mock hoisting rules

**Scope:** `packages/server/src/__tests__/` primarily

**Ideal for:**
- Writing unit tests for routes and libraries
- Writing integration tests
- Designing test cases (normal, error, boundary)
- Running and verifying test results

**Reference files the agent knows:**
- `packages/server/src/__tests__/unit/routes/brainstorm.test.ts` (route test)
- `packages/server/src/__tests__/unit/ui-mock/build-prompt.test.ts` (lib test)
- `packages/server/src/__tests__/unit/files/validate-serve-path.test.ts` (utility test)
- `packages/server/src/__tests__/integration/api.test.ts` (integration test)

**Note:** Frontend test framework is not yet set up - only server tests available.

---

## Selection Decision Tree

```
Is the task read-only?
  YES -> Does it need thorough codebase exploration?
    YES -> Explore (with thoroughness level)
    NO  -> Is it about architecture/planning?
      YES -> Plan
      NO  -> Explore (quick)
  NO  -> Does it only need terminal commands?
    YES -> Bash
    NO  -> Is it scoped to packages/server/?
      YES -> backend-dev (project-aware)
      NO  -> Is it scoped to packages/web/?
        YES -> frontend-dev (project-aware)
        NO  -> Is it a testing task?
          YES -> tester (project-aware)
          NO  -> Is it primarily about code cleanup?
            YES -> code-simplifier
            NO  -> general-purpose
```

## Model Selection Guide

### haiku (fastest, cheapest)
- File lookups and simple searches
- Running well-defined commands
- Straightforward single-file edits
- Template-based code generation
- Simple git operations

### sonnet (balanced - default)
- Most implementation tasks
- Multi-file changes with clear requirements
- Research requiring moderate analysis
- Code review and bug investigation

### opus (most capable, highest cost)
- Complex architectural decisions
- Nuanced multi-file refactoring
- Tasks requiring deep understanding of trade-offs
- Ambiguous requirements needing interpretation
- Critical production code changes
