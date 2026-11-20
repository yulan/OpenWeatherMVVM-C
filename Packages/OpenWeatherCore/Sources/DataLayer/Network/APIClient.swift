//
//  APIClient.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// Executes typed endpoints: builds the request, validates the status code
/// and decodes the body.
///
/// `send` is `@concurrent`: decoding always runs on the global executor, even
/// when called from the main actor and even if the project later enables
/// `NonisolatedNonsendingByDefault` ("approachable concurrency").
public struct APIClient: Sendable {
    private let httpClient: any HTTPClient

    public init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    @concurrent
    public func send<Response>(_ endpoint: Endpoint<Response>) async throws(NetworkError) -> Response {
        let request = try endpoint.makeRequest()
        // Path only: the query string carries the API key and the user's coordinates.
        let path = request.url?.path() ?? "-"
        let signpost = Log.signposter.beginInterval("HTTP request", id: Log.signposter.makeSignpostID(), "\(path, privacy: .public)")
        defer { Log.signposter.endInterval("HTTP request", signpost) }

        do throws(NetworkError) {
            let response: Response = try await execute(request)
            Log.network.debug("\(path, privacy: .public) succeeded")
            return response
        } catch {
            if error != .cancelled {
                Log.network.error("\(path, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            }
            throw error
        }
    }

    private func execute<Response: Decodable>(_ request: URLRequest) async throws(NetworkError) -> Response {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await httpClient.send(request)
        } catch is CancellationError {
            throw .cancelled
        } catch let error as URLError {
            throw error.code == .cancelled ? .cancelled : .transport(error.code)
        } catch {
            throw .transport(.unknown)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw .httpStatus(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw .decoding(String(describing: error))
        }
    }
}
