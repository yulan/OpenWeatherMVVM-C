//
//  OpenWeatherMVVMCApp.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

@main
struct OpenWeatherMVVMCApp: App {
    @State private var appCoordinator = Self.makeAppCoordinator()

    var body: some Scene {
        WindowGroup {
            if Self.isRunningUnitTests {
                // Unit tests are hosted in the app: don't trigger location
                // prompts or network calls behind their back.
                Color.clear
            } else {
                AppCoordinatorView(coordinator: appCoordinator)
            }
        }
    }

    private static func makeAppCoordinator() -> AppCoordinator {
        #if DEBUG
        if let scenario = UITestLaunch.scenario(in: ProcessInfo.processInfo.environment) {
            return AppCoordinator(container: .uiTesting(scenario), splashDuration: .zero)
        }
        #endif
        return AppCoordinator(container: .live())
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
