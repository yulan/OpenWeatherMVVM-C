//
//  StoryRepository.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

public protocol StoryRepository: Sendable {
    func stories(matching query: String, count: Int) async throws(DomainError) -> [Story]
}
