//
//  WeatherViewModel.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(WeatherDisplayModel)
        case failed(ErrorPresentation)
    }

    private(set) var state: State = .idle
    /// A failed *refresh*: shown as an alert on top of the content we already
    /// have, instead of replacing good data with a full-screen error.
    private(set) var refreshError: ErrorPresentation?

    var isRefreshErrorPresented: Bool {
        get { refreshError != nil }
        set { if !newValue { refreshError = nil } }
    }

    weak var navigator: (any WeatherNavigating)?

    @ObservationIgnored private let fetchCurrentWeather: any FetchCurrentWeatherUseCase
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private var weather: Weather?
    @ObservationIgnored private var lastError: DomainError?
    @ObservationIgnored private var isLoading = false

    init(fetchCurrentWeather: any FetchCurrentWeatherUseCase, locale: Locale = .autoupdatingCurrent) {
        self.fetchCurrentWeather = fetchCurrentWeather
        self.locale = locale
    }

    // MARK: - Inputs

    /// Loads once; subsequent appearances keep the current content.
    func onAppear() async {
        guard state == .idle else { return }
        await load()
    }

    /// Initial load, pull-to-refresh and retry.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let isRefreshing = if case .loaded = state { true } else { false }
        if !isRefreshing { state = .loading }

        do {
            let weather = try await fetchCurrentWeather.execute()
            self.weather = weather
            lastError = nil
            refreshError = nil
            state = .loaded(WeatherDisplayModel(weather: weather, locale: locale))
        } catch {
            guard let presentation = ErrorPresentation(error) else {
                // Cancelled before anything was shown: let the next appearance retry.
                if state == .loading { state = .idle }
                return
            }
            lastError = error
            if isRefreshing {
                refreshError = presentation
            } else {
                state = .failed(presentation)
            }
        }
    }

    /// The user may have granted location access in Settings while we were
    /// in the background: pick it up without making them tap "Try Again".
    func sceneDidBecomeActive() async {
        guard lastError == .locationPermissionDenied else { return }
        await load()
    }

    func recover(_ recovery: ErrorPresentation.Recovery) async {
        switch recovery {
        case .retry: await load()
        case .openSettings: navigator?.openAppSettings()
        }
    }

    func storiesTapped() {
        guard let weather else { return }
        navigator?.showStories(for: weather.locationName)
    }
}
