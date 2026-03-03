# Example: Parallel Feature Development

## Scenario
Add a new "user settings" feature with API endpoint + UI page.

## Execution

### Step 1: Research (parallel, haiku model)

```
Task(subagent_type="Explore", model="haiku",
  prompt="Find the existing patterns for API routes in packages/server/src/routes/
  and how they connect to services. Report the file structure and conventions used.")

Task(subagent_type="Explore", model="haiku",
  prompt="Find the existing page components in packages/web/src/app/ and identify
  the layout patterns, data fetching approach, and component conventions.")
```

### Step 2: Implement (parallel, using project custom agents)

```
Task(subagent_type="backend-dev",
  prompt="Create a user settings API endpoint.
  Add GET and PUT routes at routes/settings.ts.
  Add settings columns to the DB schema if needed.")

Task(subagent_type="frontend-dev",
  prompt="Create a user settings page.
  Add a new page at app/[locale]/settings/page.tsx.
  Include a form that calls the settings API.")
```

### Step 3: Test & Verify

```
Task(subagent_type="tester",
  prompt="Write unit tests for the new settings route.
  Cover GET and PUT, including validation errors.")
```

## Key Points
- Research phase uses Explore (read-only, fast) with haiku (cheap)
- Implementation uses `backend-dev` and `frontend-dev` (project context pre-loaded, scoped to their packages)
- Testing uses `tester` (knows mock patterns and test conventions)
- No need to repeat coding conventions in the prompt - custom agents already know them
