# Interpretation

- `PASS`: scanned scope is complete and no disallowed match exists.
- `REVIEW`: a match may be legitimate but needs inspection.
- `FAIL`: behavior contradicts the frozen offline/no-permission scope.
- `BLOCKED`: required project files were missing or unreadable.

`UserDefaults` or `@AppStorage` is not automatically a privacy issue. Document the exact key and value type, and require a target privacy manifest with `NSPrivacyAccessedAPICategoryUserDefaults` plus an appropriate accessed-API reason before calling the app submission-ready.

An `https://` string in comments or documentation is not runtime networking. Inspect context.

The absence of static matches does not prove runtime behavior; build, launch, and inspect the final app as well.
