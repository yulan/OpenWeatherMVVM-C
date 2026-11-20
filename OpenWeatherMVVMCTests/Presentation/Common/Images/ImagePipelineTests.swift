//
//  ImagePipelineTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
@testable import OpenWeatherMVVMC
import Testing

@Suite("ImagePipeline")
struct ImagePipelineTests {
    private let url = URL(string: "https://example.com/1.jpg")!

    private func makeSUT(_ stub: ImageFetchStub) -> ImagePipeline {
        ImagePipeline(fetch: stub.fetch)
    }

    @Test("Downloads and decodes once, then serves from memory")
    func memoryCache() async throws {
        let stub = ImageFetchStub(.image)
        let sut = makeSUT(stub)
        #expect(sut.cachedImage(for: url) == nil)

        let first = try await sut.image(for: url)
        let second = try await sut.image(for: url)

        #expect(stub.requestedURLs == [url])
        #expect(first === second)
        #expect(sut.cachedImage(for: url) === first)
    }

    @Test("Concurrent requests for the same URL share one download")
    func deduplicatesInFlightRequests() async throws {
        let stub = ImageFetchStub(.image, delay: .milliseconds(200))
        let sut = makeSUT(stub)

        async let a = sut.image(for: url)
        async let b = sut.image(for: url)
        async let c = sut.image(for: url)
        let images = try await [a, b, c]

        #expect(stub.requestedURLs.count == 1)
        #expect(images[0] === images[1] && images[1] === images[2])
    }

    @Test("Different URLs are downloaded separately")
    func differentURLs() async throws {
        let stub = ImageFetchStub(.image)
        let sut = makeSUT(stub)
        let other = URL(string: "https://example.com/2.jpg")!

        _ = try await sut.image(for: url)
        _ = try await sut.image(for: other)

        #expect(stub.requestedURLs == [url, other])
    }

    @Test("A failure isn't cached: the next request tries again")
    func failureNotCached() async throws {
        let stub = ImageFetchStub(.offline, .image)
        let sut = makeSUT(stub)

        await #expect(throws: URLError.self) { try await sut.image(for: url) }
        _ = try await sut.image(for: url)

        #expect(stub.requestedURLs.count == 2)
    }

    @Test("An HTTP error status is a failure, not a broken image", arguments: [404, 500])
    func httpStatus(code: Int) async {
        let sut = makeSUT(ImageFetchStub(.status(code)))

        await #expect(throws: ImagePipeline.Failure.httpStatus(code)) { try await sut.image(for: url) }
        #expect(sut.cachedImage(for: url) == nil)
    }

    @Test("Data that isn't an image is a failure")
    func undecodable() async {
        let sut = makeSUT(ImageFetchStub(.garbage))

        await #expect(throws: ImagePipeline.Failure.undecodable) { try await sut.image(for: url) }
    }

    @Test("A prefetch and a later request share one download")
    func prefetchWarmsCache() async throws {
        let stub = ImageFetchStub(.image, delay: .milliseconds(100))
        let sut = makeSUT(stub)

        sut.prefetch([url])
        _ = try await sut.image(for: url)

        // Whichever reaches the pipeline first, the other reuses its work.
        #expect(stub.requestedURLs == [url])
        #expect(sut.cachedImage(for: url) != nil)
    }

    @Test("Prefetching an image already in memory does nothing")
    func prefetchSkipsCachedImages() async throws {
        let stub = ImageFetchStub(.image)
        let sut = makeSUT(stub)
        _ = try await sut.image(for: url)

        sut.prefetch([url])

        #expect(stub.requestedURLs == [url])
    }
}
