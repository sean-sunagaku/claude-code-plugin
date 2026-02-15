# Example: Multi-Agent Code Review Pipeline

## Scenario
Review a PR or recent changes from multiple perspectives before merging.

## Execution

### Step 1: Gather changes

```
Task(subagent_type="Bash", model="haiku",
  prompt="Run: git diff main...HEAD --stat && git diff main...HEAD
  Return the full diff output.")
```

### Step 2: Parallel review (3 Explore agents + 1 code-simplifier)

```
Task(subagent_type="Explore", model="sonnet",
  prompt="Security review of these changes:
  [diff]
  Check for: SQL injection, XSS, path traversal, hardcoded secrets,
  insecure dependencies, missing input validation.
  Report severity (critical/high/medium/low) for each finding.")

Task(subagent_type="Explore", model="sonnet",
  prompt="Performance review of these changes:
  [diff]
  Check for: N+1 queries, unnecessary re-renders, missing memoization,
  large bundle additions, unoptimized loops.
  Report impact (high/medium/low) for each finding.")

Task(subagent_type="Explore", model="sonnet",
  prompt="Architecture review of these changes:
  [diff]
  Check for: Consistency with existing patterns, separation of concerns,
  proper error handling, test coverage gaps, code duplication.
  Report each concern with specific file references.")

Task(subagent_type="code-simplifier", model="sonnet",
  prompt="Review these changed files for simplification opportunities:
  [list of changed files]
  Focus on: readability, redundancy, naming, unnecessary complexity.")
```

### Step 3: Synthesize

Combine all review results into a unified report with:
- Critical issues (must fix before merge)
- Suggestions (nice to have)
- Positive observations

## Key Points
- All 4 review agents run in parallel - total time = slowest single review
- Each agent has a focused perspective - avoids review blind spots
- Explore agents are read-only, preventing accidental modifications
- code-simplifier can suggest concrete refactoring changes
- Use sonnet for nuanced analysis; haiku would miss subtleties
