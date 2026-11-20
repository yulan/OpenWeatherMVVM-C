//
//  StoryImageView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

/// Remote story image that reports when the story can start its timer: on
/// success, and also on failure (a broken image must not freeze the carousel).
///
/// A prefetched image is read synchronously from the memory cache in `init`,
/// so it appears on the first frame with no spinner.
struct StoryImageView: View {
    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    let url: URL
    let loader: any ImageLoading
    let onFinished: () -> Void

    @State private var phase: Phase

    init(url: URL, loader: any ImageLoading, onFinished: @escaping () -> Void) {
        self.url = url
        self.loader = loader
        self.onFinished = onFinished
        _phase = State(initialValue: loader.cachedImage(for: url).map(Phase.loaded) ?? .loading)
    }

    var body: some View {
        content
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case let .loaded(image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        case .failed:
            Image(symbol: .photoPlaceholder)
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.6))
        case .loading:
            ProgressView().tint(.white)
        }
    }

    private func load() async {
        if case .loading = phase {
            let result: Phase
            do {
                result = .loaded(try await loader.image(for: url))
            } catch {
                result = .failed
            }
            // The download is shared and keeps running; this view may be gone.
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { phase = result }
        }
        onFinished()
    }
}
