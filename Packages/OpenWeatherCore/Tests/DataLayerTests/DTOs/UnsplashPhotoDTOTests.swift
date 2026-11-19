//
//  UnsplashPhotoDTOTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("UnsplashPhotoDTO mapping")
struct UnsplashPhotoDTOTests {
    @Test("Prefers the description, falls back to alt text")
    func caption() throws {
        let photos = try JSONDecoder().decode([UnsplashPhotoDTO].self, from: Data(Fixtures.unsplashPhotos.utf8))
        #expect(photos.map { $0.toDomain()?.caption } == ["Eiffel tower at dusk", "Seine"])
    }

    @Test("An unusable image URL drops the entry instead of failing the batch")
    func invalidURL() {
        let dto = UnsplashPhotoDTO(id: "x", description: nil, altDescription: nil, urls: .init(regular: ""), user: nil)
        #expect(dto.toDomain() == nil)
    }
}
