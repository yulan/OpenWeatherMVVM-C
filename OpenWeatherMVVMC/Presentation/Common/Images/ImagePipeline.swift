//
//  ImagePipeline.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
import UIKit

/// Loads, decodes and caches remote images.
///
/// - **Memory**: decoded images in an `NSCache` (bounded by cost, emptied
///   under memory pressure). A hit costs no network request and no decoding.
/// - **Disk**: the injected `fetch` is backed by a `URLSession` whose
///   `URLCache` follows the server's HTTP cache headers.
/// - **Deduplication**: one in-flight download per URL, shared by every
///   caller, including prefetches.
/// - **Decoding** happens off the main thread (`byPreparingForDisplay`), so
///   showing the image never stalls scrolling or transitions.
///
/// Why not only `AsyncImage`: its caching APIs (`AsyncImage(request:)`,
/// `asyncImageURLSession(_:)`) need iOS 27 while we support iOS 18. It also
/// has no prefetching, no shared in-flight requests and no memory cache of
/// decoded images.
actor ImagePipeline: ImageLoading, ImagePrefetching {
    typealias Fetch = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    enum Failure: Error, Equatable {
        case httpStatus(Int)
        case undecodable
    }

    private let fetch: Fetch
    private let memoryCache: ImageMemoryCache
    private var inFlight: [URL: Task<UIImage, any Error>] = [:]

    /// - Parameter memoryLimit: approximate bytes of decoded images to keep.
    init(memoryLimit: Int = 100 * 1024 * 1024, fetch: @escaping Fetch) {
        self.fetch = fetch
        self.memoryCache = ImageMemoryCache(costLimit: memoryLimit)
    }

    nonisolated func cachedImage(for url: URL) -> UIImage? {
        memoryCache.image(for: url)
    }

    func image(for url: URL) async throws -> UIImage {
        if let image = memoryCache.image(for: url) { return image }
        if let download = inFlight[url] { return try await download.value }

        // Unstructured on purpose: several callers wait on the same download,
        // so one cancelled caller (e.g. the user swiped away) must not cancel
        // it for the others. A finished download still warms the cache.
        let download = Task { [fetch, memoryCache] in
            let image = try await Self.load(url, using: fetch)
            memoryCache.insert(image, for: url)
            return image
        }
        inFlight[url] = download
        defer { inFlight[url] = nil }
        return try await download.value
    }

    nonisolated func prefetch(_ urls: [URL]) {
        for url in urls where memoryCache.image(for: url) == nil {
            Task(priority: .utility) { _ = try? await self.image(for: url) }
        }
    }

    @concurrent
    private static func load(_ url: URL, using fetch: Fetch) async throws -> UIImage {
        let (data, response) = try await fetch(URLRequest(url: url))
        guard (200..<300).contains(response.statusCode) else {
            throw Failure.httpStatus(response.statusCode)
        }
        guard let image = UIImage(data: data) else { throw Failure.undecodable }
        return await image.byPreparingForDisplay() ?? image
    }
}

/// `NSCache` is documented as thread-safe but isn't annotated `Sendable`;
/// this wrapper exposes only its thread-safe calls.
private final class ImageMemoryCache: @unchecked Sendable {
    private let cache = NSCache<NSURL, UIImage>()

    init(costLimit: Int) {
        cache.totalCostLimit = costLimit
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 1
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

extension ImagePipeline {
    /// Production pipeline: its own `URLSession` with a 150 MB disk cache, so
    /// story photos don't compete with (or get evicted by) API responses.
    static func live() -> ImagePipeline {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 0, // decoded images are cached above, in memory
            diskCapacity: 150 * 1024 * 1024,
            directory: URL.cachesDirectory.appending(path: "StoryImages", directoryHint: .isDirectory)
        )
        let session = URLSession(configuration: configuration)
        return ImagePipeline { request in
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            return (data, httpResponse)
        }
    }
}
