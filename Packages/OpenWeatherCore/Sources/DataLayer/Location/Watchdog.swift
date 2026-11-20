//
//  Watchdog.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Synchronization

struct TimeoutError: Error, Equatable {}

/// A timeout whose countdown can be suspended and resumed.
///
/// Why not a plain `Task.sleep` race: while the system location prompt is on
/// screen, the user may take as long as they like to answer. That time must
/// not count against the "no GPS fix" timeout.
final class Watchdog: Sendable {
    typealias Instant = ContinuousClock.Instant

    private let timeout: Duration
    private let pollInterval: Duration
    /// `nil` while suspended.
    private let deadline: Mutex<Instant?>

    /// Every method takes the current instant as a parameter (defaulting to
    /// `.now`), so the countdown rules are unit-tested with explicit instants
    /// instead of real sleeps that flake on a busy CI machine.
    init(timeout: Duration, pollInterval: Duration = .milliseconds(250), startingAt start: Instant = .now) {
        self.timeout = timeout
        self.pollInterval = pollInterval
        self.deadline = Mutex(start + timeout)
    }

    func suspend() {
        deadline.withLock { $0 = nil }
    }

    /// Restarts a full countdown if suspended; no-op if already running.
    func resume(at now: Instant = .now) {
        deadline.withLock { if $0 == nil { $0 = now + timeout } }
    }

    /// Never true while suspended.
    func isExpired(at now: Instant = .now) -> Bool {
        deadline.withLock { $0.map { now >= $0 } ?? false }
    }

    /// Throws `TimeoutError` once the deadline passes. Never returns normally.
    func run() async throws -> Never {
        while true {
            if isExpired() { throw TimeoutError() }
            // Wake at the deadline or the next poll, whichever comes first, then
            // re-check: the deadline may have been suspended or moved meanwhile.
            let wake = deadline.withLock { $0 }.map { min($0, .now + pollInterval) } ?? .now + pollInterval
            try await Task.sleep(until: wake, clock: .continuous)
        }
    }
}

/// Runs `operation` against `watchdog`; whichever finishes first wins and the
/// other child task is cancelled.
func withWatchdog<T: Sendable>(
    _ watchdog: Watchdog,
    operation: @escaping @Sendable (Watchdog) async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation(watchdog) }
        group.addTask { try await watchdog.run() }
        defer { group.cancelAll() }
        guard let result = try await group.next() else { throw CancellationError() }
        return result
    }
}
