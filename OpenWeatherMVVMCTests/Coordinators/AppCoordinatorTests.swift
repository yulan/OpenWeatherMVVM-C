//
//  AppCoordinatorTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import OpenWeatherMVVMC
import Testing

@MainActor
@Suite("AppCoordinator")
struct AppCoordinatorTests {
    @Test("Moves from splash to the weather flow")
    func startsWeatherFlow() async {
        let sut = AppCoordinator(container: .stub(), splashDuration: .zero)
        #expect(sut.isLaunching)

        await sut.start()

        guard case .running = sut.phase else {
            Issue.record("Expected running phase")
            return
        }
    }

    @Test("Starting twice keeps the same child coordinator")
    func startIsIdempotent() async throws {
        let sut = AppCoordinator(container: .stub(), splashDuration: .zero)

        await sut.start()
        guard case let .running(first) = sut.phase else { throw CoordinatorTestError.notRunning }
        await sut.start()
        guard case let .running(second) = sut.phase else { throw CoordinatorTestError.notRunning }

        #expect(first === second)
    }

    private enum CoordinatorTestError: Error { case notRunning }
}
