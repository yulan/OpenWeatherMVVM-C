//
//  WeatherCoordinator.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Observation
import UIKit

/// Owns the weather flow: the weather screen and the stories it presents.
@MainActor
@Observable
final class WeatherCoordinator: Coordinator {
    enum Destination: Identifiable {
        case stories(StoriesViewModel)

        var id: ObjectIdentifier {
            switch self {
            case let .stories(viewModel): ObjectIdentifier(viewModel)
            }
        }
    }

    /// Presented full-screen. Holding the ViewModel here (not in the view)
    /// ties its lifetime to the presentation.
    var destination: Destination?

    let weatherViewModel: WeatherViewModel

    @ObservationIgnored private let container: AppDependencyContainer

    init(container: AppDependencyContainer) {
        self.container = container
        self.weatherViewModel = container.makeWeatherViewModel()
        weatherViewModel.navigator = self
    }

    /// Handed to the stories view, alongside its ViewModel.
    var imageLoader: any ImageLoading { container.imageLoader }

    func start() async {}
}

// MARK: - WeatherNavigating

extension WeatherCoordinator: WeatherNavigating {
    func showStories(for city: String) {
        guard destination == nil else { return }
        let viewModel = container.makeStoriesViewModel(city: city)
        viewModel.navigator = self
        destination = .stories(viewModel)
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        container.urlOpener.open(url)
    }
}

// MARK: - StoriesNavigating

extension WeatherCoordinator: StoriesNavigating {
    func closeStories() {
        destination = nil
    }
}
