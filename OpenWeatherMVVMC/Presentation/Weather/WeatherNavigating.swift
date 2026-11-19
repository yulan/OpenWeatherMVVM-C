//
//  WeatherNavigating.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

/// Navigation intents the weather screen can express. Implemented by a
/// coordinator; the ViewModel never knows who handles them.
@MainActor
protocol WeatherNavigating: AnyObject {
    func showStories(for city: String)
    func openAppSettings()
}
