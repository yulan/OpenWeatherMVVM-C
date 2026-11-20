# AGENTS.md

Instructions for AI coding agents (Claude Code, Codex, Cursor…) working in this repository. Humans follow the same rules in [CONTRIBUTING.md](CONTRIBUTING.md); the reasons are in [docs/adr](docs/adr).

## Project map

- `Packages/OpenWeatherCore/Sources/Domain`: entities, `DomainError`, repository protocols, use cases. **No imports except Foundation.**
- `Packages/OpenWeatherCore/Sources/DataLayer`: `APIClient`, endpoints, DTOs (`internal`), repositories, `FileWeatherStore`, `CoreLocationRepository`.
- `OpenWeatherMVVMC/App`: `@main`, `AppDependencyContainer` (the only place that knows concrete types), `Log`.
- `OpenWeatherMVVMC/Coordinators`: navigation state and flows.
- `OpenWeatherMVVMC/Presentation`: `@MainActor @Observable` ViewModels, views, `DesignSystem` (`L10n`, `AppSymbol`), `Common/Images` (`ImagePipeline`).
- `Shared/`: compiled into both the app and the UI tests (accessibility identifiers, UI-test launch contract).
- Tests mirror the source tree in `OpenWeatherMVVMCTests/`, `OpenWeatherMVVMCUITests/` and `Packages/OpenWeatherCore/Tests/`.

## Commands

```bash
bundle exec fastlane package_tests   # Domain + Data, ~1 s, run after every package change
bundle exec fastlane test            # full test plan on a simulator
bundle exec fastlane ci              # what CI runs
```

## Rules you must follow

1. **Dependency rule:** Domain imports nothing; DataLayer imports Domain; the app imports both. Never expose a DTO or an infrastructure error outside DataLayer: map to `DomainError`.
2. **Swift 6, strict concurrency, zero warnings.** No stored `Task` in ViewModels. Prefer `Mutex` over `@unchecked Sendable`.
3. **No literals in views:** wording goes in `L10n` + `Localizable.xcstrings` (add **both** `en` and `fr`), symbols in `AppSymbol`, colors in the asset catalog. Keep the catalog's JSON formatting: add keys, don't reserialize the file.
4. **Tests:**
   - Every behaviour change ships with tests in the mirrored path.
   - Never depend on wall-clock timing; inject a `Clock` or explicit instants.
   - Never widen access control just to test.
5. **File header** on every new Swift file (not `Package.swift`): `//  FileName.swift`, `//  TargetName`, `//  Created by Lan YU on dd/MM/yyyy.`
6. **Logging:** `Log.<category>`. Never log API keys, full request URLs or coordinates in clear text.
7. **Secrets:** never read, print or commit `Configurations/Secrets.xcconfig`.
8. **Git:** never commit, push or rewrite history unless the human asks. Conventional Commits; each commit must build.

## Before you say "done"

- Run the relevant lane and read the result. Don't assume it passed.
- **Verify every claim you write** in a PR description, README or ADR against the code or the `.xcresult`. Count tests in the result bundle: a green run only proves that whatever ran passed. (Package tests were once silently skipped by an Xcode scheme.)
- Check the edge cases a reviewer will try: offline, permission denied, empty results, a single item, cancellation, French locale, dark mode.
- Run the `ios-reviewer` agent (`.claude/agents/ios-reviewer.md`) on your diff and address its findings.
