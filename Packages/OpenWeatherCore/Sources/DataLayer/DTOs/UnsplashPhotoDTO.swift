//
//  UnsplashPhotoDTO.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

struct UnsplashPhotoDTO: Decodable, Sendable {
    struct URLs: Decodable, Sendable {
        let regular: String
    }

    struct User: Decodable, Sendable {
        let name: String?
    }

    let id: String
    let description: String?
    let altDescription: String?
    let urls: URLs
    let user: User?

    enum CodingKeys: String, CodingKey {
        case id, description, urls, user
        case altDescription = "alt_description"
    }
}

extension UnsplashPhotoDTO {
    /// Returns `nil` for entries whose image URL is unusable rather than
    /// failing the whole batch.
    func toDomain() -> Story? {
        guard let url = URL(string: urls.regular) else { return nil }
        return Story(
            id: id,
            imageURL: url,
            caption: description ?? altDescription,
            photographerName: user?.name
        )
    }
}
