# 0003. A closed `DomainError` vocabulary with typed throws

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

Infrastructure errors (`URLError`, `DecodingError`, CoreLocation states) leak easily into ViewModels. The UI then needs `if let urlError = error as? URLError` checks, and new failure modes silently fall into a generic message.

## Decision

- `Domain.DomainError` is a closed enum: `locationPermissionDenied`, `locationUnavailable`, `offline`, `unauthorized`, `server(statusCode:)`, `invalidResponse`, `cancelled`, `unknown`.
- Repositories and use cases declare `throws(DomainError)` (typed throws).
- The Data layer translates everything at its boundary: `NetworkError.domainError` maps URL error codes and HTTP statuses, and `CoreLocationRepository` maps authorization states and timeouts.
- `ErrorPresentation` turns a `DomainError` into wording, a symbol and a recovery action. Cancellation maps to `nil` and is never shown.

## Alternatives considered

- **Untyped `throws` with casting in the UI:** the compiler can't tell us when a case is unhandled.
- **`Result<T, DomainError>` everywhere:** same guarantees, but noisier than `try` with async/await.

## Consequences

- ViewModels `switch` exhaustively; adding a case is a compile error until every screen handles it.
- `NetworkErrorTests` documents the whole mapping table in one place.
- Typed throws have rough edges: `do` blocks need `do throws(NetworkError)` to keep the type, and wrapping closures (task groups) still produce `any Error`, so `CoreLocationRepository` maps again at that boundary.
