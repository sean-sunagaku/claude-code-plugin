# Example: Research -> Plan -> Implement

## Scenario
Optimize slow database queries in the server package.

## Execution

### Step 1: Research (parallel Explore agents)

```
Task(subagent_type="Explore", thoroughness="very thorough",
  prompt="Find all database queries in packages/server/src/ that might be slow.
  Look for: N+1 queries, missing indexes, full table scans, large joins.
  Report each file, line number, and the concern.")

Task(subagent_type="Explore",
  prompt="Read the Drizzle ORM schema files in packages/server/src/db/
  and list all tables, their columns, indexes, and relationships.")
```

### Step 2: Plan (single Plan agent, after research)

```
Task(subagent_type="Plan",
  prompt="Based on these findings:
  [Paste research results]

  Design an optimization plan:
  1. Which queries to optimize and how
  2. What indexes to add
  3. Priority order (most impactful first)
  4. Any schema changes needed")
```

### Step 3: Implement (sequential, general-purpose)

```
Task(subagent_type="general-purpose",
  prompt="Implement the following database optimizations:
  [Paste plan]

  Make changes to the Drizzle schema and query files.
  Generate migrations with: pnpm drizzle-kit generate")
```

### Step 4: Verify

```
Task(subagent_type="Bash", run_in_background=true,
  prompt="Run the test suite: cd /path/to/project && pnpm --filter server test")
```

## Key Points
- Research uses Explore for read-only analysis
- Plan agent synthesizes findings into actionable steps
- Implementation agent receives complete context from prior phases
- Verification runs in background to not block conversation
