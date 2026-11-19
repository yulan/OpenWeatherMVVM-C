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
