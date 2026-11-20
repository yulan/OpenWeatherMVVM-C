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

    // MARK: Countdown rules: explicit instants, no sleeping, deterministic

    private let start = ContinuousClock.now

    @Test("Expires exactly when the timeout has elapsed")
    func expiresAtDeadline() {
        let watchdog = Watchdog(timeout: .seconds(10), startingAt: start)

        #expect(!watchdog.isExpired(at: start + .seconds(9.9)))
        #expect(watchdog.isExpired(at: start + .seconds(10)))
    }

    @Test("Never expires while suspended")
    func suspendedNeverExpires() {
        let watchdog = Watchdog(timeout: .seconds(10), startingAt: start)

        watchdog.suspend()

        #expect(!watchdog.isExpired(at: start + .seconds(3600)))
    }

    @Test("Time spent suspended (e.g. permission prompt on screen) doesn't count")
    func suspendedTimeDoesNotCount() {
        let watchdog = Watchdog(timeout: .seconds(10), startingAt: start)

        watchdog.suspend()                             // prompt shown at once
        watchdog.resume(at: start + .seconds(60))      // user answers a minute later

        #expect(!watchdog.isExpired(at: start + .seconds(69)))
        #expect(watchdog.isExpired(at: start + .seconds(70)))
    }

    @Test("Resuming while already running doesn't extend the deadline")
    func resumeWhileRunningIsNoOp() {
        let watchdog = Watchdog(timeout: .seconds(10), startingAt: start)

        watchdog.resume(at: start + .seconds(5))

        #expect(watchdog.isExpired(at: start + .seconds(10)))
    }
}
