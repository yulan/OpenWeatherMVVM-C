# 0005. An image pipeline instead of `AsyncImage`

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

Stories auto-advance every 3 s, and a story's timer only starts once its image is on screen. On a slow network the user waits on every story. We need prefetching, and a prefetched image must appear on the first frame.

Xcode 27's SDK adds HTTP caching to `AsyncImage`, `AsyncImage(request:)` and `.asyncImageURLSession(_:)`, but both APIs are `@available(anyAppleOS 27.0, *)` and we support iOS 18.

## Decision

`ImagePipeline`, an `actor` in the app target:

- **memory:** decoded `UIImage`s in an `NSCache`, bounded by byte cost and emptied under memory pressure;
- **disk:** a dedicated `URLSession` with a 150 MB `URLCache` that follows HTTP cache headers;
- **deduplication:** one in-flight download per URL, shared by every caller. It is an unstructured `Task` on purpose: one cancelled caller must not cancel a download others are waiting for;
- **decoding** off the main thread with `byPreparingForDisplay()`.

Two protocols split it by consumer:

- `ImagePrefetching` (URLs only) for `StoriesViewModel`, which prefetches story n+1;
- `ImageLoading` for `StoryImageView`, which reads the memory cache synchronously in `init`.

## Alternatives considered

- **`AsyncImage` on iOS 18:** uses `URLCache.shared` (small, shared with API calls) and has no prefetch.
- **`AsyncImage` + `asyncImageURLSession` on iOS 27:** still no prefetch, no shared in-flight requests, no decoded-image cache.
- **Nuke / Kingfisher:** excellent, but a dependency for one screen, and the pipeline is about 100 lines.

## Consequences

- The next story usually appears instantly, and the "wait for the image" rule rarely waits.
- The ViewModel never imports UIKit; prefetching is tested with a spy.
- `ImageMemoryCache` is the project's only `@unchecked Sendable`: `NSCache` is documented thread-safe but not annotated.
- When the minimum target reaches iOS 27, re-evaluate. `AsyncImage` could then cover the disk layer, and the pipeline would keep only prefetch and memory.
