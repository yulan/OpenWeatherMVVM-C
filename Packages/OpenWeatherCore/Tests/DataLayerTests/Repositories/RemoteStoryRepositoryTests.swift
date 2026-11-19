//
//  RemoteStoryRepositoryTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("RemoteStoryRepository")
struct RemoteStoryRepositoryTests {
    @Test("Builds the Unsplash request with auth header and query")
    func buildsRequest() async throws {
        let client = HTTPClientStub.json(Fixtures.unsplashPhotos)
        let sut = RemoteStoryRepository(apiClient: APIClient(httpClient: client), accessKey: "ACCESS")

        _ = try await sut.stories(matching: "Paris", count: 5)

        let request = try #require(client.receivedRequests.first)
        #expect(request.url?.host() == "api.unsplash.com")
        #expect(request.url?.path() == "/photos/random")
        #expect(request.queryValue("query") == "Paris")
        #expect(request.queryValue("count") == "5")
        #expect(request.queryValue("orientation") == "portrait")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Client-ID ACCESS")
        #expect(request.value(forHTTPHeaderField: "Accept-Version") == "v1")
    }

    @Test("Maps photos to stories, preferring description over alt text")
    func mapsPhotos() async throws {
        let sut = RemoteStoryRepository(apiClient: APIClient(httpClient: HTTPClientStub.json(Fixtures.unsplashPhotos)), accessKey: "A")

        let stories = try await sut.stories(matching: "Paris", count: 2)

        #expect(stories == [
            Story(
                id: "abc",
                imageURL: URL(string: "https://images.unsplash.com/photo-abc")!,
                caption: "Eiffel tower at dusk",
                photographerName: "Jane Doe"
            ),
            Story(
                id: "def",
                imageURL: URL(string: "https://images.unsplash.com/photo-def")!,
                caption: "Seine",
                photographerName: nil
            ),
        ])
    }

    @Test("Rate limiting surfaces as a server error")
    func rateLimited() async {
        let sut = RemoteStoryRepository(
            apiClient: APIClient(httpClient: HTTPClientStub.json("{}", status: 429)),
            accessKey: "A"
        )
        await #expect(throws: DomainError.server(statusCode: 429)) {
            try await sut.stories(matching: "Paris", count: 5)
        }
    }

    @Test("Missing access key fails fast")
    func missingKey() async {
        let client = HTTPClientStub.json(Fixtures.unsplashPhotos)
        let sut = RemoteStoryRepository(apiClient: APIClient(httpClient: client), accessKey: "")

        await #expect(throws: DomainError.unauthorized) { try await sut.stories(matching: "Paris", count: 5) }
        #expect(client.receivedRequests.isEmpty)
    }
}
