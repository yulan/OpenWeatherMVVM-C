//
//  UnsplashAPI.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

enum UnsplashAPI {
    static let baseURL = URL(string: "https://api.unsplash.com")!

    /// https://unsplash.com/documentation#get-a-random-photo
    static func randomPhotos(query: String, count: Int, accessKey: String) -> Endpoint<[UnsplashPhotoDTO]> {
        Endpoint(
            baseURL: baseURL,
            path: "photos/random",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "count", value: String(count)),
                URLQueryItem(name: "orientation", value: "portrait"),
                URLQueryItem(name: "content_filter", value: "high"),
            ],
            headers: [
                "Authorization": "Client-ID \(accessKey)",
                "Accept-Version": "v1",
            ]
        )
    }
}
