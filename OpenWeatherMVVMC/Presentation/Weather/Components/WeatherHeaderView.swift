//
//  WeatherHeaderView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct WeatherHeaderView: View {
    let model: WeatherDisplayModel

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text(model.date)
                    .font(.title3)
                Text(model.lastUpdated)
                    .font(.footnote)
            }
            .foregroundStyle(.white.opacity(0.8))

            Text(model.locationName)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Image(systemName: model.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 72))
                .padding(.vertical, 8)
                .accessibilityHidden(true)

            Text(model.temperature)
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .contentTransition(.numericText())

            Text(model.conditionDescription)
                .font(.title3.weight(.medium))

            Text(model.highLow)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityID.Weather.header)
    }
}
