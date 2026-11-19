//
//  StoryImageView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

/// `AsyncImage` that reports when the story can start its timer: on success,
/// and also on failure (a broken image must not freeze the carousel).
struct StoryImageView: View {
    let url: URL
    let onFinished: () -> Void

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
                    .onAppear(perform: onFinished)
            case .failure:
                Image(symbol: .photoPlaceholder)
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.6))
                    .onAppear(perform: onFinished)
            default:
                ProgressView().tint(.white)
            }
        }
    }
}
