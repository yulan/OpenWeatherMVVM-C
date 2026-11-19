//
//  SkyGradient.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct SkyGradient: View {
    let isNight: Bool

    var body: some View {
        LinearGradient(
            colors: isNight ? [Color(.skyNightTop), Color(.skyNightBottom)] : [Color(.skyDayTop), Color(.skyDayBottom)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: isNight)
    }
}
