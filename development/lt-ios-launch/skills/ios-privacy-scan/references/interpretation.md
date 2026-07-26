# Interpretation

- `PASS`: scanned scope is complete and no disallowed match exists.
- `REVIEW`: a match may be legitimate but needs inspection.
- `FAIL`: behavior contradicts the frozen offline/no-permission scope.
- `BLOCKED`: required project files were missing or unreadable.

`UserDefaults` or `@AppStorage` is not automatically a privacy issue. Document the exact key and value type.

An `https://` string in comments or documentation is not runtime networking. Inspect context.

The absence of static matches does not prove runtime behavior; build, launch, and inspect the final app as well.
