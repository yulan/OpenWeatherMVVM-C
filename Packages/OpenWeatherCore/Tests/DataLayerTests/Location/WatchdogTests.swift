//
//  WatchdogTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Testing

@Suite("Watchdog")
struct WatchdogTests {
    @Test("Returns the operation result when it finishes in time")
    func returnsResult() async throws {
        let value = try await withWatchdog(Watchdog(timeout: .seconds(5))) { _ in 42 }
        #expect(value == 42)
    }

    @Test("Times out when the operation is too slow")
    func timesOut() async {
        let watchdog = Watchdog(timeout: .milliseconds(30), pollInterval: .milliseconds(5))
        await #expect(throws: TimeoutError()) {
            try await withWatchdog(watchdog) { _ in
                try await Task.sleep(for: .seconds(10))
                return 0
            }
        }
    }

    @Test("Time spent suspended (e.g. permission prompt on screen) doesn't count")
    func suspendedTimeDoesNotCount() async throws {
        let watchdog = Watchdog(timeout: .milliseconds(80), pollInterval: .milliseconds(5))

        let value = try await withWatchdog(watchdog) { watchdog in
            watchdog.suspend()
            try await Task.sleep(for: .milliseconds(200)) // > timeout while suspended
            watchdog.resume()
            try await Task.sleep(for: .milliseconds(20))  // < timeout after resuming
            return "fix"
        }

        #expect(value == "fix")
    }

    @Test("Resuming restarts a full countdown")
    func resumeRestartsCountdown() async {
        let watchdog = Watchdog(timeout: .milliseconds(40), pollInterval: .milliseconds(5))
        await #expect(throws: TimeoutError()) {
            try await withWatchdog(watchdog) { watchdog in
                watchdog.suspend()
                watchdog.resume()
                try await Task.sleep(for: .seconds(10))
                return 0
            }
        }
    }
}
