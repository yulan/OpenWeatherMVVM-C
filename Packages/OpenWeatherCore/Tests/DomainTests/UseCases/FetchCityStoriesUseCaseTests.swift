//
//  FetchCityStoriesUseCaseTests.swift
//  DomainTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Testing

@Suite("FetchCityStoriesUseCase")
struct FetchCityStoriesUseCaseTests {
    @Test("Queries the repository with the trimmed city and configured count")
    func queriesWithCityAndCount() async throws {
        let repository = StoryRepositorySpy(result: .success([.fixture(id: "a")]))
        let sut = DefaultFetchCityStoriesUseCase(repository: repository, storyCount: 3)

        let stories = try await sut.execute(city: "  Paris \n")

        #expect(stories.map(\.id) == ["a"])
        #expect(repository.calls == [.init(query: "Paris", count: 3)])
    }

    @Test("Falls back to a generic query when the city is blank")
    func blankCityFallsBack() async throws {
        let repository = StoryRepositorySpy(result: .success([]))
        let sut = DefaultFetchCityStoriesUseCase(repository: repository)

        _ = try await sut.execute(city: "   ")

        #expect(repository.calls.first?.query == "city skyline")
        #expect(repository.calls.first?.count == DefaultFetchCityStoriesUseCase.defaultStoryCount)
    }

    @Test("Removes duplicate stories while preserving order")
    func removesDuplicates() async throws {
        let repository = StoryRepositorySpy(result: .success([
            .fixture(id: "a"), .fixture(id: "b"), .fixture(id: "a"), .fixture(id: "c"),
        ]))
        let sut = DefaultFetchCityStoriesUseCase(repository: repository)

        let stories = try await sut.execute(city: "Paris")

        #expect(stories.map(\.id) == ["a", "b", "c"])
    }

    @Test("Propagates repository errors")
    func propagatesErrors() async {
        let sut = DefaultFetchCityStoriesUseCase(repository: StoryRepositorySpy(result: .failure(.unauthorized)))
        await #expect(throws: DomainError.unauthorized) { try await sut.execute(city: "Paris") }
    }
}
