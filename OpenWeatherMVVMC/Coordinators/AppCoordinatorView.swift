//
//  AppCoordinatorView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct AppCoordinatorView: View {
    let coordinator: AppCoordinator

    var body: some View {
        ZStack {
            switch coordinator.phase {
            case .launching:
                SplashView()
                    .transition(.opacity)
            case let .running(weatherCoordinator):
                WeatherCoordinatorView(coordinator: weatherCoordinator)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: coordinator.isLaunching)
        .task { await coordinator.start() }
    }
}
