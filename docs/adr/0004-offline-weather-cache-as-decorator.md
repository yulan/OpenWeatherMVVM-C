# 0004. Offline weather cache as a repository decorator

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

Without a network the app showed "You're Offline" even when it had shown valid weather minutes earlier. We want a fallback without spreading caching logic through the use case and the ViewModel.

## Decision

`CachedWeatherRepository` wraps any `WeatherRepository`:

- on success, it saves the result through `WeatherStore` (`FileWeatherStore`: one JSON file in Caches, written atomically) and returns it;
- on `.offline` only, it returns the saved weather if it is **less than 24 h old** and **within 25 km** of the current location; otherwise it rethrows.

The file format is `WeatherRecord`, a DataLayer type with a `version` field. A missing, corrupt or older-format file is a cache miss.

The header always shows "Updated 2 hours ago" (from `Weather.observedAt`), so saved data is never mistaken for live data.

## Alternatives considered

- **Cache inside the use case:** mixes policy with orchestration and changes every use-case test.
- **Make `Weather` `Codable`:** less code, but the persistence format then changes whenever the entity does.
- **SwiftData / Core Data:** a database for one record.
- **Return freshness metadata with `Weather`:** would let the UI say "offline" explicitly, but changes the protocol, the use case and the ViewModel.

## Consequences

- The use case, the ViewModel and their existing tests did not change. The wiring is one line in `AppDependencyContainer`.
- A bad API key or a server error is never hidden behind old data.
- Trade-off accepted: a pull-to-refresh while offline shows the saved data with its age instead of an "offline" alert.
- Not exercised on a device: the simulator can't cut the network, so the fallback is covered by `CachedWeatherRepositoryTests` and `FileWeatherStoreTests`.
