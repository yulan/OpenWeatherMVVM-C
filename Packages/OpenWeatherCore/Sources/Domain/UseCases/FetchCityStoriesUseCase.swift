//
//  FetchCityStoriesUseCase.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// Fetches a short series of photos illustrating a city.
public protocol FetchCityStoriesUseCase: Sendable {
    func execute(city: String) async throws(DomainError) -> [Story]
}

public struct DefaultFetchCityStoriesUseCase: FetchCityStoriesUseCase {
    public static let defaultStoryCount = 5
    static let fallbackQuery = "city skyline"

    private let repository: any StoryRepository
    private let storyCount: Int

    public init(repository: any StoryRepository, storyCount: Int = Self.defaultStoryCount) {
        precondition(storyCount > 0, "storyCount must be positive")
        self.repository = repository
        self.storyCount = storyCount
    }

    public func execute(city: String) async throws(DomainError) -> [Story] {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = trimmed.isEmpty ? Self.fallbackQuery : trimmed
        let stories = try await repository.stories(matching: query, count: storyCount)
        // The API occasionally returns duplicates for narrow queries.
        var seen = Set<Story.ID>()
        return stories.filter { seen.insert($0.id).inserted }
    }
}
