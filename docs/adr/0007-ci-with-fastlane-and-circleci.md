# 0007. CI with Fastlane lanes and CircleCI

- **Status:** Accepted
- **Date:** 2026-11-20

## Context

Tests that only run on a developer's machine stop being run. CI must run all four test bundles on every push, and a red build must be reproducible locally with one command.

## Decision

- **Fastlane lanes are the single source of truth** (`fastlane/Fastfile`):
  - `package_tests`: `swift test` on macOS, about 1 s;
  - `test`: the whole `OpenWeatherMVVMC.xctestplan` on a simulator, with a JUnit report and an `.xcresult`;
  - `ci`: both, in that order.
- **CircleCI only calls lanes** (`.circleci/config.yml`). It uses Xcode 27.2 on `m4pro.medium`. The package job gates the simulator job, so a broken Domain fails in seconds, not minutes.
- **Fastlane is pinned** with `Gemfile.lock`, so CI and every developer run the same version.
- **No secrets are needed:** tests run on stubs and the app builds without API keys.

## Alternatives considered

- **GitHub Actions** (`xcode-27` runner): equally valid and closer to the repository. CircleCI + Fastlane was chosen to match the team's existing tooling. Because jobs only call lanes, switching providers is a small change.
- **Raw `xcodebuild` in the CI config:** works, but then the CI file and developers' commands drift apart.

## Consequences

- `bundle exec fastlane ci` reproduces CI locally.
- The first local run surfaced a flaky test: `WatchdogTests` relied on real 80 ms timeouts and failed under load. `Watchdog` now takes explicit instants and its rules are tested without sleeping. **Rule: unit tests never depend on wall-clock timing.**
- Ruby and Bundler become a development dependency.
