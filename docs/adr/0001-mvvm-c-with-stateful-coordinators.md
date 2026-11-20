# 0001. Use MVVM-C with coordinators that own navigation state

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

The app was first written with The Composable Architecture (TCA). We want a version that a typical iOS team can join without learning a framework, that keeps navigation testable, and that maps to both SwiftUI and UIKit.

## Decision

- **View** renders state and forwards intents. No logic.
- **ViewModel** is `@MainActor @Observable`. It holds a `State` enum, calls use cases and maps errors. It talks to navigation only through a narrow protocol (`WeatherNavigating`, `StoriesNavigating`) held `weak`.
- **Coordinator** is `@MainActor @Observable` and owns navigation *state* (`phase`, `destination`). It creates ViewModels through the container and implements the `*Navigating` protocols. A companion `*CoordinatorView` renders that state with `switch` and `fullScreenCover(item:)`.
- **`AppDependencyContainer`** is the only place that knows concrete types.

## Alternatives considered

- **Keep TCA:** strong testing story, but a large dependency and a steep learning curve for a two-screen app.
- **`NavigationPath` in a global router:** global mutable state, and it is unclear which screen owns which ViewModel.
- **Navigation inside views (`@State var showStories`):** navigation becomes untestable without UI tests.

## Consequences

- ViewModel tests use navigator spies; coordinator tests check `destination` directly. Neither needs a UI.
- A presented ViewModel lives exactly as long as its presentation, because the coordinator holds it.
- Moving to UIKit only changes coordinators (`UINavigationController`, `present`); ViewModels and their tests don't change.
- More types than "a view with a ViewModel": each flow has a coordinator and a coordinator view.
