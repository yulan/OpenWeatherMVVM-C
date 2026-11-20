# Contributing

How we work on this codebase. The *why* behind each rule is in [docs/adr](docs/adr). Coding agents follow the same rules through [AGENTS.md](AGENTS.md).

## Setup

Requirements: Xcode 27+ (CI uses 27.2), Ruby 3.x with Bundler.

```bash
cp Configurations/Secrets.example.xcconfig Configurations/Secrets.xcconfig   # then add your API keys
bundle install                                                               # pinned Fastlane
```

API keys are only needed to run the app against the real services. Tests never need them.

## Running the tests

| Command | What it runs | Time |
|---|---|---|
| `bundle exec fastlane package_tests` | Domain + DataLayer tests, natively on macOS | ~1 s |
| `bundle exec fastlane test` | The whole test plan: package, unit and UI tests on a simulator | a few minutes |
| `bundle exec fastlane ci` | Exactly what CircleCI runs | a few minutes |

`⌘U` in Xcode runs the same test plan. If CI is red, run the same lane locally before anything else.

## Architecture rules

| Layer | Lives in | May import | Must not |
|---|---|---|---|
| Domain | `Packages/OpenWeatherCore/Sources/Domain` | Foundation only | know about networking, CoreLocation, UIKit, SwiftUI |
| Data | `Packages/OpenWeatherCore/Sources/DataLayer` | Domain | expose DTOs (keep them `internal`) or throw anything but `DomainError` |
| Presentation | `OpenWeatherMVVMC/Presentation` | Domain | call repositories directly (go through use cases) |
| Coordinators | `OpenWeatherMVVMC/Coordinators` | Presentation | contain screen logic |
| Composition | `OpenWeatherMVVMC/App/AppDependencyContainer.swift` | everything | — it is the only place that knows concrete types |

## Adding a screen

1. **Domain:** add an entity or use case if the screen needs new business rules. Write its tests in `DomainTests`.
2. **Data:** add an endpoint, a DTO and a repository. Map every failure to `DomainError`.
3. **ViewModel:** `@MainActor @Observable final class`, with a `State` enum and intent methods. Navigation goes through a `<Feature>Navigating` protocol held `weak`. Inject a `Clock` and a `Locale` where time or formatting matters.
4. **View:** render state, forward intents, nothing else. Gesture *decisions* belong in the ViewModel.
5. **Coordinator:** create the ViewModel through a factory method on `AppDependencyContainer`, and implement the navigating protocol.
6. **Tests:** mirror the source path, e.g. `Presentation/Weather/WeatherViewModel.swift` → `OpenWeatherMVVMCTests/Presentation/Weather/WeatherViewModelTests.swift`.
7. **Decision worth explaining?** Add an ADR in the same pull request.

## Conventions

- **File header** on every Swift file except `Package.swift`:
  ```swift
  //
  //  FileName.swift
  //  TargetName
  //
  //  Created by Lan YU on dd/MM/yyyy.
  //
  ```
- **Wording** goes in `Localizable.xcstrings` (en + fr) behind `L10n`. **SF Symbols** go in `AppSymbol`. **Colors** go in the asset catalog. No literals in views.
- **Concurrency:** Swift 6 language mode with strict checking. Don't store a `Task` in a ViewModel: use `.task {}` / `.task(id:)`. Use `Mutex` rather than `@unchecked Sendable`; if you truly need the latter, document why next to it.
- **Logging:** use `Log.<category>` (`os.Logger`). Interpolated values are private by default; mark one `.public` only when it can never contain personal data or secrets. Never log a full API URL: the query string carries the key.
- **Tests:**
  - Swift Testing for unit tests, XCUITest for flows.
  - Never depend on wall-clock timing: inject a `Clock` or explicit instants.
  - Never make a member non-private just to test it: drive public inputs instead.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org): `feat(scope):`, `fix(scope):`, `test(scope):`, `docs:`, `chore:`. One logical change per commit. Each commit builds.

## Code review checklist

Reviewers check, and authors check first:

- [ ] Layer rules above are respected; no DTO or infrastructure error escapes the Data layer.
- [ ] Every new behaviour has a test, every bug fix has a regression test, and tests sit in the mirrored path.
- [ ] Edge cases are handled: offline, permission denied, empty results, cancellation, a single item, slow network.
- [ ] Nothing is user-visible in English only: `L10n`, and units/dates formatted for the locale.
- [ ] Readable in dark mode and at large Dynamic Type sizes; VoiceOver labels on custom controls.
- [ ] No timing-dependent tests, no stored `Task` in ViewModels, no new `@unchecked Sendable` without a comment.
- [ ] Docs and comments match the code. If the PR says "tested", say how, and check the counts in the `.xcresult`.

## Definition of done

`bundle exec fastlane ci` is green locally, there are no new warnings, the PR template is filled in, and screenshots are attached for UI changes (light and dark).
