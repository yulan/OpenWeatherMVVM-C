//
//  RemoteStoryRepository.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

public struct RemoteStoryRepository: StoryRepository {
    private let apiClient: APIClient
    private let accessKey: String

    public init(apiClient: APIClient, accessKey: String) {
        self.apiClient = apiClient
        self.accessKey = accessKey
    }

    public func stories(matching query: String, count: Int) async throws(DomainError) -> [Story] {
        guard !accessKey.isEmpty else { throw .unauthorized }

        let endpoint = UnsplashAPI.randomPhotos(query: query, count: count, accessKey: accessKey)
        let photos: [UnsplashPhotoDTO]
        do throws(NetworkError) {
            photos = try await apiClient.send(endpoint)
        } catch {
            throw error.domainError
        }
        return photos.compactMap { $0.toDomain() }
    }
}
