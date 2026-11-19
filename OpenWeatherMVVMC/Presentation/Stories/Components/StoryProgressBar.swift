//
//  StoryProgressBar.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

struct StoryProgressBar: View {
    let count: Int
    let progress: (Int) -> Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.3))
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(.white)
                                .frame(width: proxy.size.width * progress(index))
                        }
                    }
                    .clipShape(.capsule)
            }
        }
        .frame(height: 3)
        .accessibilityHidden(true)
    }
}
