//
//  WeatherView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct WeatherView: View {
    @Bindable var viewModel: WeatherViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            SkyGradient(isNight: isNight)
            content
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .task { await viewModel.onAppear() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await viewModel.sceneDidBecomeActive() }
        }
        .alert(
            viewModel.refreshError?.title ?? "",
            isPresented: $viewModel.isRefreshErrorPresented,
            presenting: viewModel.refreshError
        ) { error in
            Button(error.recovery.title) {
                Task { await viewModel.recover(error.recovery) }
            }
            Button(role: .cancel) {} label: { Text(L10n.Error.dismiss) }
        } message: { error in
            Text(error.message)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            WeatherContentView(model: .placeholder, onStoriesTapped: {})
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(L10n.Weather.loading))
                .phaseAnimator([1.0, 0.5]) { view, opacity in
                    view.opacity(opacity)
                } animation: { _ in .easeInOut(duration: 0.9) }

        case let .loaded(model):
            WeatherContentView(model: model, onStoriesTapped: viewModel.storiesTapped)
                .refreshable { await viewModel.load() }

        case let .failed(error):
            ErrorStateView(error: error) {
                Task { await viewModel.recover(error.recovery) }
            }
        }
    }

    private var isNight: Bool {
        if case let .loaded(model) = viewModel.state { model.isNight } else { false }
    }
}

#Preview("Loaded") {
    WeatherView(viewModel: .preview(.success(.sample)))
}

#Preview("Permission denied") {
    WeatherView(viewModel: .preview(.failure(.locationPermissionDenied)))
}

#Preview("Offline – dark") {
    WeatherView(viewModel: .preview(.failure(.offline)))
        .preferredColorScheme(.dark)
}
