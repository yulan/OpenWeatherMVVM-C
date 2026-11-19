//
//  Story.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// A single full-screen image in the stories carousel.
public struct Story: Identifiable, Hashable, Sendable {
    public let id: String
    public let imageURL: URL
    public let caption: String?
    /// Required for attribution by the Unsplash API guidelines.
    public let photographerName: String?

    public init(id: String, imageURL: URL, caption: String?, photographerName: String?) {
        self.id = id
        self.imageURL = imageURL
        self.caption = caption
        self.photographerName = photographerName
    }
}
