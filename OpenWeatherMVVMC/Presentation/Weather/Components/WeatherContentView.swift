//
//  WeatherContentView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

/// Stateless rendering of a `WeatherDisplayModel`. Reused for the loading
/// skeleton (redacted placeholder) so both layouts can never drift apart.
struct WeatherContentView: View {
    let model: WeatherDisplayModel
    let onStoriesTapped: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                let layout = verticalSizeClass == .compact
                    ? AnyLayout(HStackLayout(alignment: .center, spacing: 32))
                    : AnyLayout(VStackLayout(spacing: 24))
                layout {
                    WeatherHeaderView(model: model)
                    WeatherMetricsGrid(model: model)
                }

                Button(action: onStoriesTapped) {
                    Label {
                        Text(L10n.Weather.viewStories)
                    } icon: {
                        Image(symbol: .viewStories)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard(cornerRadius: 16)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(L10n.Weather.viewStoriesHint(model.locationName)))
                .accessibilityIdentifier(AccessibilityID.Weather.storiesButton)
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(.white)
    }
}
