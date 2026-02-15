---
name: agent-team
description: This skill should be used when the user asks to "create a team", "spawn agents", "parallel execution", "delegate tasks to agents", "use a swarm", "team workflow", "split work across agents", "run tasks in parallel", or mentions wanting multiple agents to collaborate on a complex task.
---

# Agent Team Orchestration

Orchestrate multi-agent teams to decompose complex tasks, select optimal sub-agents, and execute work in parallel.

## When to Use

- Tasks requiring parallel work across multiple domains (frontend + backend, research + implementation)
- Complex multi-step tasks benefiting from specialization (plan, implement, test, review)
- Large-scale refactoring or feature development spanning many files
- Tasks requiring both research and implementation phases

## Core Workflow

### 1. Task Decomposition

Analyze the user's request and break it into independent, parallelizable units:

1. Identify the goal and deliverables
2. Split into sub-tasks that can run concurrently
3. Identify dependencies between sub-tasks (what blocks what)
4. Assign each sub-task to the optimal agent type

### 2. Agent Type Selection

Select the optimal `subagent_type` for each sub-task based on the work required.

#### Built-in Agents

| Agent Type | Best For | Tools Available |
|---|---|---|
| `general-purpose` | Implementation, file editing, full-stack work | All tools (Read, Write, Edit, Bash, Glob, Grep, etc.) |
| `Explore` | Codebase research, finding patterns, understanding architecture | Read-only (Glob, Grep, Read, WebFetch, WebSearch) |
| `Plan` | Design decisions, architecture planning, implementation strategy | Read-only (same as Explore) |
| `Bash` | Git operations, build commands, CLI tasks | Bash only |
| `code-simplifier` | Refactoring, cleanup, code quality improvements | All tools |

#### Project Custom Agents (`.claude/agents/`)

Specialized agents with project-specific context pre-loaded. **Prefer these over `general-purpose` when the task falls within their domain.**

| Agent Type | Domain | Scope Restriction |
|---|---|---|
| `backend-dev` | Hono + Drizzle ORM + SQLite API 実装 | `packages/server/` のみ |
| `frontend-dev` | Next.js 16 + React 19 + Tailwind UI 実装 | `packages/web/` のみ |
| `tester` | Vitest テスト設計・実装・実行 | `packages/server/src/__tests__/` |

Custom agents already know the project's coding conventions, file structure, and reference files -- no need to repeat this context in the prompt.

#### Selection Rules

- Research/investigation -> `Explore` (fast, read-only)
- Architecture planning -> `Plan` (structured output, read-only)
- Backend API changes -> **`backend-dev`** (project-aware, scoped to server)
- Frontend UI changes -> **`frontend-dev`** (project-aware, scoped to web)
- Test writing/execution -> **`tester`** (project-aware, knows mock patterns)
- Cross-package or general changes -> `general-purpose` (full access)
- Build/deploy commands -> `Bash` (minimal overhead)
- Refactoring -> `code-simplifier` (specialized for cleanup)

### 3. Team Spawn Pattern

**For parallel independent tasks** (no team coordination needed):

```
Use multiple Task tool calls in a single message:
- Task 1: subagent_type="Explore", prompt="Research X"
- Task 2: subagent_type="general-purpose", prompt="Implement Y"
- Task 3: subagent_type="Bash", prompt="Run tests"
```

**For coordinated multi-step tasks** (team with shared task list):

```
1. TeamCreate -> create team with name and description
2. TaskCreate -> create all tasks with dependencies
3. Task tool -> spawn teammates with team_name parameter
4. TaskUpdate -> assign tasks to teammates
5. Monitor progress via TaskList
6. SendMessage -> coordinate as needed
7. Shutdown teammates when done
8. TeamDelete -> clean up
```

### 4. Model Selection

Optimize cost and latency by selecting the right model per agent:

| Model | When to Use |
|---|---|
| `haiku` | Simple tasks: file lookups, running commands, straightforward edits |
| `sonnet` | Most tasks: implementation, research, moderate complexity |
| `opus` | Complex tasks: architecture decisions, nuanced analysis, multi-file refactoring |

Default: inherit parent model. Override with the `model` parameter on the Task tool.

## Common Team Patterns

### Pattern A: Research-then-Implement

Parallel research phase, then sequential implementation:

```
Phase 1 (parallel):
  - Explore agent: "Investigate current codebase patterns for X"
  - Explore agent: "Find all files related to Y"
  - Plan agent: "Design approach for Z"

Phase 2 (after results):
  - general-purpose agent: "Implement based on research findings"
```

### Pattern B: Parallel Feature Development

Split frontend/backend using project custom agents:

```
Parallel:
  - backend-dev agent: "Implement API endpoint for user settings"
  - frontend-dev agent: "Build settings page UI"
  - tester agent: "Write tests for the new settings route"
```

### Pattern C: Review Pipeline

Multi-stage quality assurance:

```
Sequential:
  1. general-purpose: "Implement feature"
  2. Parallel review:
     - Explore: "Check for security issues"
     - Explore: "Verify test coverage"
     - code-simplifier: "Simplify and refactor"
```

### Pattern D: Large-Scale Refactoring

Divide-and-conquer across file groups:

```
Phase 1 (Explore): "Map all files needing changes"
Phase 2 (parallel general-purpose agents):
  - Agent 1: "Refactor module A files"
  - Agent 2: "Refactor module B files"
  - Agent 3: "Refactor module C files"
Phase 3 (Bash): "Run full test suite"
```

## Key Guidelines

### Parallelization Rules

- Launch independent tasks in a **single message** with multiple Task tool calls
- Use `run_in_background: true` for long-running tasks that don't need immediate results
- Check background task results with the Read tool on the `output_file`

### Agent Communication

- Teammates communicate via `SendMessage` (plain text, not JSON)
- Messages are delivered automatically - no polling needed
- Use `broadcast` only for critical team-wide issues
- Idle state is normal - send a message to wake a teammate

### Task Dependencies

- Use `addBlockedBy` / `addBlocks` to establish ordering
- Teammates should check `TaskList` after completing each task
- Prefer ID order (lowest first) when multiple tasks are available

### Cost Optimization

- Use `haiku` model for simple, well-defined subtasks
- Use `Explore` instead of `general-purpose` for read-only work (faster, cheaper)
- Avoid spawning teams for tasks completable in a single agent turn
- Minimize broadcasts - prefer targeted messages

## Additional Resources

### Reference Files

For detailed agent selection criteria and advanced patterns:
- **`references/subagent-types.md`** - Complete guide to each agent type with capabilities and limitations
- **`references/team-patterns.md`** - Advanced team patterns with real-world examples

### Example Files

Working team configurations:
- **`examples/parallel-feature.md`** - Parallel frontend + backend development
- **`examples/research-implement.md`** - Research phase followed by implementation
- **`examples/review-pipeline.md`** - Multi-agent code review pipeline
