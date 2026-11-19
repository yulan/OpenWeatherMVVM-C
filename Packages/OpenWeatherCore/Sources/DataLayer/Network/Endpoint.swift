//
//  Endpoint.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// A typed description of an HTTP call. The response type is part of the
/// endpoint so call sites can't decode the wrong model.
public struct Endpoint<Response: Decodable & Sendable>: Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
    }

    let baseURL: URL
    let path: String
    let method: Method
    let queryItems: [URLQueryItem]
    let headers: [String: String]

    init(
        baseURL: URL,
        path: String,
        method: Method = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
    }

    func makeRequest(timeout: TimeInterval = 20) throws(NetworkError) -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw .invalidRequest
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw .invalidRequest }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
