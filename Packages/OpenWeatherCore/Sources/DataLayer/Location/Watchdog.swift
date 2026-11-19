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
    private let timeout: Duration
    private let pollInterval: Duration
    /// `nil` while suspended.
    private let deadline: Mutex<ContinuousClock.Instant?>

    init(timeout: Duration, pollInterval: Duration = .milliseconds(250)) {
        self.timeout = timeout
        self.pollInterval = pollInterval
        self.deadline = Mutex(.now + timeout)
    }

    func suspend() {
        deadline.withLock { $0 = nil }
    }

    /// Restarts a full countdown if suspended; no-op if already running.
    func resume() {
        deadline.withLock { if $0 == nil { $0 = .now + timeout } }
    }

    /// Throws `TimeoutError` once the deadline passes. Never returns normally.
    func run() async throws -> Never {
        while true {
            guard let current = deadline.withLock({ $0 }) else {
                try await Task.sleep(for: pollInterval)
                continue
            }
            if ContinuousClock.now >= current { throw TimeoutError() }
            // Re-read after waking: the deadline may have been suspended or moved.
            try await Task.sleep(until: min(current, .now + pollInterval), clock: .continuous)
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
