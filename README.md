# OpenWeatherMVVM-C

A rewrite of [OpenWeatherTCATest](../OpenWeatherTCATest) using **MVVM-C (Model-View-ViewModel + Coordinator)** on top of **Clean Architecture**, with **Swift 6** strict concurrency, **SwiftUI**, `@Observable` and **Swift Concurrency**. The app has no third-party dependencies (Fastlane is a development tool only).

It has the same features as the TCA version:

1. **Weather**: locates the user and shows the current weather from OpenWeatherMap. Offline, it falls back to the last saved weather (if it is less than 24 h old and within 25 km), and the header always says how old the data is. Units follow the user's region: °F, mph and inHg in the US; °C and mph in the UK; °C and km/h in France.
2. **Stories**: Instagram-style full-screen photos of the city from Unsplash. They auto-advance every 3 s, and you can tap or swipe to navigate and hold to pause. The next photo is prefetched while the current one is on screen.

---

## Architecture

```
┌──────────────────────────── App target (OpenWeatherMVVMC) ────────────────────────────┐
│                                                                                       │
│  App/            Composition root: AppDependencyContainer, AppConfiguration           │
│  Coordinators/   AppCoordinator ─▶ WeatherCoordinator      (navigation state + flow)  │
│  Presentation/   Views  ◀──observes──  @Observable @MainActor ViewModels              │
│                                         │  navigation intents via *Navigating protocol│
└─────────────────────────────────────────┼─────────────────────────────────────────────┘
                                          ▼ depends on use-case protocols
┌──────────── Packages/OpenWeatherCore (local SPM) ────────────┐
│  DataLayer   APIClient, Endpoints, DTOs, Remote*Repository,  │
│              CachedWeatherRepository (decorator),            │
│              FileWeatherStore, CoreLocationRepository        │
│                                              ──implements──▶ │
│  Domain      Entities, DomainError, Repository protocols,    │
│              Use cases                (no dependencies)       │
└──────────────────────────────────────────────────────────────┘
```

**The dependency rule is enforced by the compiler.** `Domain` and `DataLayer` are separate Swift modules, so `Domain` cannot import CoreLocation, UIKit or SwiftUI. The Presentation layer only sees use-case protocols, and infrastructure types (`URLError`, `DecodingError`, CoreLocation states) are translated into `DomainError` before they leave the Data layer.

### MVVM-C in SwiftUI

| Role | Responsibility |
|---|---|
| **View** | Renders state and forwards user intents to the ViewModel. Holds no logic. |
| **ViewModel** | `@MainActor @Observable`. Holds screen state (`State` enum), calls use cases and maps errors to `ErrorPresentation`. Expresses navigation through a narrow protocol (`WeatherNavigating`, `StoriesNavigating`) and never refers to a coordinator type. |
| **Coordinator** | `@MainActor @Observable`. Owns navigation *state* (phase, presented destination), creates ViewModels through the container and implements the `*Navigating` protocols. Its companion `*CoordinatorView` renders that state (`switch phase`, `fullScreenCover(item:)`). |
| **Container** | Composition root. It is the only place that knows the concrete implementations. |

Navigation flow:

```
AppCoordinator   .launching ──(splash)──▶ .running(WeatherCoordinator)
WeatherCoordinator   WeatherViewModel ──showStories(city)──▶ destination = .stories(StoriesViewModel)
                     StoriesViewModel ──closeStories()────▶ destination = nil
                     WeatherViewModel ──openAppSettings()─▶ URLOpening
```

### TCA → MVVM-C mapping

| TCA version | This version |
|---|---|
| `AppReducer` composing `LocationReducer` + `WeatherReducer` | `FetchCurrentWeatherUseCase` (location → weather) + `AppCoordinator` |
| `WeatherReducer.State` / `Action` | `WeatherViewModel.State` enum + intent methods |
| `@Dependency(\.weatherRepository)` | Constructor injection through `AppDependencyContainer` |
| `showStories` bool + `navigationDestination` inside the view | `WeatherCoordinator.destination` + `fullScreenCover(item:)` |
| `AlertState` for permission denied | `ErrorPresentation` with `.openSettings` recovery in a shared `ErrorStateView`, plus an automatic reload when returning from Settings |
| `Timer` in `StoriesView` | `StoriesViewModel.play()` on an injected `Clock`, with logic in the pure `advance(by:)` |
| `LocationManagerDelegate` + `CheckedContinuation` | `CLServiceSession` + `CLLocationUpdate.liveUpdates()` with a timeout |
| `DeviceOrientationManager` / `UIDevice.isPad` | `verticalSizeClass`, adaptive grid, Dynamic Type |
| `TestStore` (XCTest) | Swift Testing (`@Test`, parameterized tests, `#expect(throws:)`) |

### Swift 6 concurrency choices

- Swift 6 language mode with `SWIFT_STRICT_CONCURRENCY = complete`. The project builds with **zero warnings**.
- The UI layer (ViewModels, Coordinators, Container) is `@MainActor`. Domain and Data are `Sendable` value types with nonisolated `async` APIs, so JSON decoding runs off the main actor.
- **Typed throws** (`throws(DomainError)`) at every repository and use-case boundary, so ViewModels `switch` exhaustively over errors.
- Lifetime is structured: work runs in `.task {}` / `.task(id:)` and is cancelled automatically when the view disappears. No ViewModel stores a `Task`. Cancellation maps to `DomainError.cancelled` and is never shown to the user.
- `APIClient.send` is explicitly `@concurrent`, so decoding is guaranteed to run off the main actor.
- Story images go through `ImagePipeline`, an `actor` that shares one in-flight download per URL between all callers (prefetches included), keeps decoded images in memory and decodes off the main thread.
- Test doubles use `Synchronization.Mutex` instead of `@unchecked Sendable`.

### Observability

- `os.Logger` per layer (`network`, `location`, `cache`, `images`, `ui`), all under the app's bundle identifier, so one Console filter shows a whole session. Values are private by default; API keys and coordinates never appear in clear text.
- `OSSignposter` intervals (*HTTP request*, *Location fix*, *Image download*) show up in Instruments' *Points of Interest*.
- Errors that used to be swallowed (a failed cache write, an unreadable saved file) are now logged.

---

## Project structure

```
OpenWeatherMVVM-C/
├── OpenWeatherMVVMC.xcodeproj         (synchronized folders: add files without touching the project)
├── OpenWeatherMVVMC.xctestplan        runs all 4 test bundles (package + app + UI)
├── fastlane/Fastfile                  package_tests, test, ci lanes (what CI runs)
├── .circleci/config.yml               CircleCI: package job gates the simulator job
├── docs/adr/                          Architecture Decision Records
├── CONTRIBUTING.md                    setup, architecture rules, review checklist
├── AGENTS.md, CLAUDE.md               the same rules for AI coding agents
├── .claude/agents/ios-reviewer.md     review agent for diffs
├── Configurations/
│   ├── Base.xcconfig                  #include? "Secrets.xcconfig"
│   ├── Secrets.example.xcconfig       → copy to Secrets.xcconfig (git-ignored)
│   └── Info.plist                     keys injected from build settings
├── Shared/                            compiled into app AND UI tests: AccessibilityID, UITestLaunch
├── OpenWeatherMVVMC/
│   ├── App/                           @main, AppDependencyContainer, AppConfiguration, URLOpening
│   │   └── Debug/                     #if DEBUG stubs for previews and UI tests
│   ├── Coordinators/                  Coordinator, AppCoordinator(+View), WeatherCoordinator(+View)
│   ├── Presentation/
│   │   ├── DesignSystem/              L10n (all wording), AppSymbol (all SF Symbols)
│   │   ├── Common/                    ErrorPresentation, ErrorStateView, GlassCard, SkyGradient
│   │   │   └── Images/                ImageLoading / ImagePrefetching, ImagePipeline (actor)
│   │   ├── Splash/
│   │   ├── Weather/                   WeatherViewModel, WeatherDisplayModel, WeatherView, Components/
│   │   └── Stories/                   StoriesViewModel, StoriesView, Components/
│   └── Resources/                     Assets (AppIcon, color tokens), Localizable.xcstrings (en, fr)
├── OpenWeatherMVVMCTests/             mirrors the app: App/, Coordinators/, Presentation/…, Support/
├── OpenWeatherMVVMCUITests/           end-to-end flows on deterministic stubs
└── Packages/OpenWeatherCore/
    ├── Sources/Domain/                Entities, Errors, Repositories (protocols), UseCases
    ├── Sources/DataLayer/             Network, Endpoints, DTOs, Repositories, Persistence, Location
    └── Tests/                         mirror the sources: UseCases/, Network/, DTOs/, Repositories/, Persistence/, Location/
```

---

## Getting started

Requirements: Xcode 27+ (CI uses 27.2), iOS 18.0+, and Ruby with Bundler for Fastlane.

1. Add your API keys:
   ```bash
   cp Configurations/Secrets.example.xcconfig Configurations/Secrets.xcconfig
   ```
   Then fill in `OPENWEATHER_API_KEY` and `UNSPLASH_ACCESS_KEY`. Without them the app still builds and shows a "Service Unavailable" error.
2. Open `OpenWeatherMVVMC.xcodeproj` and run the **OpenWeatherMVVMC** scheme. In the Simulator, pick a location under *Features ▸ Location*.

## Tests

`⌘U` runs the test plan; so does Fastlane, which is what CI calls:

```bash
bundle install                        # once
bundle exec fastlane package_tests    # Domain + Data on macOS, ~1 s
bundle exec fastlane test             # whole test plan on a simulator
bundle exec fastlane ci               # both: exactly what CircleCI runs
```

Last verified run, read from the `.xcresult`:

| Bundle | Test functions | Framework |
|---|---|---|
| DomainTests | 7 | Swift Testing |
| DataLayerTests | 40 | Swift Testing |
| OpenWeatherMVVMCTests | 70 | Swift Testing |
| OpenWeatherMVVMCUITests | 3 | XCTest (XCUITest) |

Parameterized tests count once here; they expand to many cases. No unit test depends on wall-clock timing: time is injected as a `Clock` or as explicit instants.

---

## Contributing

- [CONTRIBUTING.md](CONTRIBUTING.md): setup, architecture rules, how to add a screen, the code review checklist.
- [docs/adr](docs/adr): why the code looks the way it does. One decision per file, with the alternatives we rejected.
- [AGENTS.md](AGENTS.md): the same rules for AI coding agents. Claude Code loads it through `CLAUDE.md`, and `.claude/agents/ios-reviewer.md` reviews a diff against the checklist.

---

## License

MIT. See [LICENSE](LICENSE).
