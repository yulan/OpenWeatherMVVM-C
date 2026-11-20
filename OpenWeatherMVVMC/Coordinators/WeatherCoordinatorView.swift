//
//  WeatherCoordinatorView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct WeatherCoordinatorView: View {
    @Bindable var coordinator: WeatherCoordinator

    var body: some View {
        NavigationStack {
            WeatherView(viewModel: coordinator.weatherViewModel)
        }
        .fullScreenCover(item: $coordinator.destination) { destination in
            switch destination {
            case let .stories(viewModel):
                StoriesView(viewModel: viewModel, imageLoader: coordinator.imageLoader)
            }
        }
    }
}
