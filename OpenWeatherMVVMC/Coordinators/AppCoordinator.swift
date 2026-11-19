//
//  AppCoordinator.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Observation

/// Root coordinator: splash → main flow. Future flows (onboarding, auth…)
/// plug in here as additional phases.
@MainActor
@Observable
final class AppCoordinator: Coordinator {
    enum Phase {
        case launching
        case running(WeatherCoordinator)
    }

    private(set) var phase: Phase = .launching

    var isLaunching: Bool {
        if case .launching = phase { true } else { false }
    }

    @ObservationIgnored private let container: AppDependencyContainer
    @ObservationIgnored private let splashDuration: Duration
    @ObservationIgnored private let clock: any Clock<Duration>

    init(
        container: AppDependencyContainer,
        splashDuration: Duration = .seconds(1.5),
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.container = container
        self.splashDuration = splashDuration
        self.clock = clock
    }

    func start() async {
        guard isLaunching else { return }
        // A cancelled sleep (e.g. scene torn down) still proceeds: the splash
        // must never become a dead end.
        try? await clock.sleep(for: splashDuration)
        guard isLaunching else { return }

        let weatherCoordinator = WeatherCoordinator(container: container)
        phase = .running(weatherCoordinator)
        await weatherCoordinator.start()
    }
}
