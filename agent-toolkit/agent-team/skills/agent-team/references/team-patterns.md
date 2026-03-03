# Advanced Team Patterns

## Pattern 1: Parallel Independent Tasks (No Team)

The simplest pattern. Launch multiple Task calls in a single message - no TeamCreate needed.

**When to use:** Tasks are independent, no shared state, no coordination needed.

```
Message with multiple Task tool calls:
  Task(subagent_type="Explore", prompt="Find all API endpoints", model="haiku")
  Task(subagent_type="Explore", prompt="Find all database models", model="haiku")
  Task(subagent_type="Bash", prompt="Run npm test", run_in_background=true)
```

**Key points:**
- All tasks launch simultaneously
- Results return as each completes
- No overhead of team management
- Best for 2-5 independent tasks

---

## Pattern 2: Research -> Plan -> Implement

Sequential phases where each informs the next.

**When to use:** Complex features requiring understanding before implementation.

```
Phase 1 - Research (parallel):
  Task(Explore): "Find all authentication-related files and patterns"
  Task(Explore): "Investigate current session management approach"

Phase 2 - Plan (after research results):
  Task(Plan): "Design JWT auth implementation based on: [research results]"

Phase 3 - Implement (after plan approval):
  Task(general-purpose): "Implement JWT auth following this plan: [plan]"

Phase 4 - Verify:
  Task(Bash): "Run test suite"
  Task(Explore): "Check for security vulnerabilities in new auth code"
```

---

## Pattern 3: Coordinated Team (TeamCreate)

Full team with shared task list and communication.

**When to use:** Long-running, multi-step work requiring coordination between agents.

### Setup

```
1. TeamCreate(team_name="feature-x", description="Implement feature X")
2. TaskCreate(subject="Research current API patterns", ...)
3. TaskCreate(subject="Implement backend API", ..., addBlockedBy=["1"])
4. TaskCreate(subject="Implement frontend UI", ..., addBlockedBy=["1"])
5. TaskCreate(subject="Write integration tests", ..., addBlockedBy=["2", "3"])
```

### Spawn Teammates

```
Task(subagent_type="Explore", team_name="feature-x", name="researcher")
Task(subagent_type="general-purpose", team_name="feature-x", name="backend-dev")
Task(subagent_type="general-purpose", team_name="feature-x", name="frontend-dev")
```

### Task Assignment

```
TaskUpdate(taskId="1", owner="researcher", status="in_progress")
# After research completes, tasks 2 and 3 become unblocked
TaskUpdate(taskId="2", owner="backend-dev")
TaskUpdate(taskId="3", owner="frontend-dev")
```

### Shutdown

```
SendMessage(type="shutdown_request", recipient="researcher")
SendMessage(type="shutdown_request", recipient="backend-dev")
SendMessage(type="shutdown_request", recipient="frontend-dev")
# After all approve:
TeamDelete()
```

---

## Pattern 4: Divide-and-Conquer Refactoring

Split large codebase changes across multiple agents.

**When to use:** Refactoring that touches many files across different modules.

```
Phase 1 - Map (single Explore agent):
  "List all files needing changes, grouped by module"

Phase 2 - Execute (parallel general-purpose agents):
  Agent A: "Refactor files in packages/server/src/routes/"
  Agent B: "Refactor files in packages/web/src/components/"
  Agent C: "Refactor files in packages/shared/src/"

Phase 3 - Verify (single Bash agent):
  "Run full lint + test suite across all packages"

Phase 4 - Fix (if needed):
  "Fix any test failures from the refactoring"
```

**Critical:** Ensure agents work on non-overlapping file sets to avoid conflicts.

---

## Pattern 5: Multi-Agent Code Review

Parallel review from different perspectives.

**When to use:** Critical code changes needing thorough review.

```
Parallel:
  Explore agent (security): "Review changes for security vulnerabilities (OWASP Top 10)"
  Explore agent (performance): "Review changes for performance issues and N+1 queries"
  Explore agent (architecture): "Review changes for architectural consistency"
  code-simplifier: "Identify simplification opportunities in changed files"
```

---

## Pattern 6: Background Workers

Long-running tasks that run while main conversation continues.

**When to use:** Tasks that take time but don't block other work.

```
Task(Bash, run_in_background=true): "Run full test suite"
Task(Bash, run_in_background=true): "Build production bundle"

# Continue working on other things...
# Check results later with Read tool on output_file
```

---

## Anti-Patterns to Avoid

### Over-teaming
Creating a full team for a task that one agent can handle. If the task can be done in <5 minutes by one agent, skip the team overhead.

### Agent Conflict
Two agents editing the same file simultaneously. Always partition work by file or module boundaries.

### Unnecessary Broadcasts
Using broadcast for messages that only concern one teammate. Always use targeted messages.

### Missing Dependencies
Not setting up blockedBy relationships, causing agents to start work before prerequisites are ready.

### Wrong Agent Type
Using general-purpose for read-only research (wasteful), or Explore for tasks needing file edits (will fail).

---

## Cost-Performance Optimization

### Minimize Agent Spawns
Each agent spawn has startup cost. Batch related work into single agents rather than spawning one per file.

### Right-Size Models
- `haiku` for grunt work (file searches, simple commands): ~10x cheaper than opus
- `sonnet` for standard implementation: good balance
- `opus` only for complex reasoning: reserve for critical decisions

### Prefer Explore Over General-Purpose
For any read-only task, Explore is faster and more focused. It won't be tempted to make unnecessary changes.

### Use Background Execution
For tasks like test suites or builds, use `run_in_background: true` to avoid blocking the conversation.
