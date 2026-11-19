//
//  WeatherMetricsGrid.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct WeatherMetricsGrid: View {
    let model: WeatherDisplayModel

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(model.metrics) { metric in
                    MetricTile(metric: metric)
                }
            }

            if let sunrise = model.sunrise, let sunset = model.sunset {
                HStack(spacing: 24) {
                    Label { Text(sunrise) } icon: { Image(symbol: .sunrise) }
                        .accessibilityLabel(Text(L10n.Weather.sunrise(sunrise)))
                    Label { Text(sunset) } icon: { Image(symbol: .sunset) }
                        .accessibilityLabel(Text(L10n.Weather.sunset(sunset)))
                }
                .font(.headline)
                .symbolRenderingMode(.multicolor)
                .frame(maxWidth: .infinity)
                .padding()
                .glassCard()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricTile: View {
    let metric: WeatherDisplayModel.Metric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label { Text(metric.title.uppercased()) } icon: { Image(symbol: metric.symbol) }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(metric.value)
                .font(.title2.weight(.medium))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}
