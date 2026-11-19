//
//  UseCaseStubs.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation
@testable import OpenWeatherMVVMC
import Synchronization

final class FetchCurrentWeatherUseCaseStub: FetchCurrentWeatherUseCase {
    private let results: Mutex<[Result<Weather, DomainError>]>
    private let calls = Mutex(0)

    /// Results are consumed in order; the last one repeats.
    init(_ results: [Result<Weather, DomainError>]) {
        precondition(!results.isEmpty)
        self.results = Mutex(results)
    }

    convenience init(_ results: Result<Weather, DomainError>...) {
        self.init(results)
    }

    var callCount: Int { calls.withLock { $0 } }

    func execute() async throws(DomainError) -> Weather {
        calls.withLock { $0 += 1 }
        let result = results.withLock { results in
            results.count > 1 ? results.removeFirst() : results[0]
        }
        return try result.get()
    }
}

final class FetchCityStoriesUseCaseStub: FetchCityStoriesUseCase {
    private let result: Result<[Story], DomainError>
    private let cities = Mutex<[String]>([])

    init(_ result: Result<[Story], DomainError>) {
        self.result = result
    }

    var requestedCities: [String] { cities.withLock { $0 } }

    func execute(city: String) async throws(DomainError) -> [Story] {
        cities.withLock { $0.append(city) }
        return try result.get()
    }
}
