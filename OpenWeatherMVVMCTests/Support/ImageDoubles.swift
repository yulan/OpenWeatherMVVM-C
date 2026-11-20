//
//  ImageDoubles.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
@testable import OpenWeatherMVVMC
import Synchronization
import UIKit

final class ImagePrefetcherSpy: ImagePrefetching {
    private let urls = Mutex<[URL]>([])

    var prefetchedURLs: [URL] { urls.withLock { $0 } }

    func prefetch(_ urls: [URL]) {
        self.urls.withLock { $0.append(contentsOf: urls) }
    }
}

/// Network double for `ImagePipeline`: counts requests and replays canned
/// replies in order (the last one repeats).
final class ImageFetchStub: Sendable {
    enum Reply: Sendable {
        case image
        case status(Int)
        case garbage
        case offline
    }

    private let replies: Mutex<[Reply]>
    private let requests = Mutex<[URL]>([])
    private let delay: Duration

    init(_ replies: Reply..., delay: Duration = .zero) {
        precondition(!replies.isEmpty)
        self.replies = Mutex(replies)
        self.delay = delay
    }

    var requestedURLs: [URL] { requests.withLock { $0 } }

    func fetch(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else { throw URLError(.badURL) }
        requests.withLock { $0.append(url) }
        if delay > .zero { try await Task.sleep(for: delay) }

        let reply = replies.withLock { $0.count > 1 ? $0.removeFirst() : $0[0] }
        func response(_ status: Int) -> HTTPURLResponse {
            HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        }
        switch reply {
        case .image: return (Self.pngData, response(200))
        case let .status(code): return (Data(), response(code))
        case .garbage: return (Data("not an image".utf8), response(200))
        case .offline: throw URLError(.notConnectedToInternet)
        }
    }

    private static let pngData = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).pngData { context in
        UIColor.orange.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }
}
