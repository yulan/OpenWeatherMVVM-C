# 0002. Modularize by layer with a local Swift package

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

Clean Architecture only holds if the dependency rule holds: Domain knows nothing, Data knows Domain, the app knows both. In a single target this rule is a convention that erodes with every "quick fix".

## Decision

`Packages/OpenWeatherCore` contains two library targets:

- **`Domain`**: entities, `DomainError`, repository protocols, use cases. No dependencies.
- **`DataLayer`**: networking, DTOs, repositories, persistence, CoreLocation. Depends on `Domain` only.

The app target holds presentation, coordinators and the composition root. Anything that needs UIKit or SwiftUI, such as `ImagePipeline`, stays in the app.

## Alternatives considered

- **Folders in one target:** cheapest, but the rule is enforced only by review, and `internal` means "visible everywhere".
- **Xcode framework targets:** same isolation, heavier project file, and no `swift test` on macOS.
- **Feature modules** (`WeatherFeature`, `StoriesFeature`, `DesignSystem`): the right next step for a bigger team or app, but over-engineering for two screens today.

## Consequences

- `import UIKit` in Domain is a compile error, not a review comment.
- DTOs are `internal` to DataLayer: the app cannot even see them.
- Domain and Data tests run with `swift test` on macOS in about a second, without a simulator.
- Public types need `public` initializers (boilerplate).
- Xcode does not run package tests from a scheme's test list; the test plan (`OpenWeatherMVVMC.xctestplan`) plus a file reference to the package is required. Count the tests in the `.xcresult` to be sure.
