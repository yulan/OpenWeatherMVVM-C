//
//  StoriesView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import SwiftUI

struct StoriesView: View {
    let viewModel: StoriesViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .tint(.white)
                    .controlSize(.large)

            case .loaded:
                if let story = viewModel.currentStory {
                    StoryPageView(story: story, viewModel: viewModel)
                }

            case let .failed(error):
                ErrorStateView(error: error) {
                    Task { await viewModel.load() }
                }
            }
        }
        .overlay(alignment: .top) {
            StoriesHeaderView(viewModel: viewModel)
        }
        .statusBarHidden()
        .task { await viewModel.loadIfNeeded() }
        .task(id: viewModel.isPlaybackActive) { await viewModel.play() }
    }
}

private struct StoriesHeaderView: View {
    let viewModel: StoriesViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isPlaybackActive {
                StoryProgressBar(count: viewModel.stories.count, progress: viewModel.progress(forStoryAt:))
            }
            HStack {
                Text(viewModel.city)
                    .font(.headline)
                    .shadow(radius: 4)
                Spacer()
                Button(action: viewModel.close) {
                    Image(symbol: .close)
                        .font(.title3.weight(.semibold))
                        .padding(10)
                        .contentShape(.circle)
                }
                .accessibilityLabel(Text(L10n.Stories.close))
                .accessibilityIdentifier(AccessibilityID.Stories.closeButton)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

/// One story: renders the image and reports raw gestures to the ViewModel.
private struct StoryPageView: View {
    let story: Story
    let viewModel: StoriesViewModel

    var body: some View {
        GeometryReader { proxy in
            StoryImageView(url: story.imageURL) {
                viewModel.storyImageDidFinishLoading(story.id)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .id(story.id)
            .overlay(alignment: .bottomLeading) { attribution }
            .contentShape(.rect)
            .onTapGesture { location in
                viewModel.handleTap(atHorizontalFraction: location.x / max(proxy.size.width, 1))
            }
            .onLongPressGesture(minimumDuration: 0.2, maximumDistance: 20) {
            } onPressingChanged: { isPressing in
                viewModel.setPaused(isPressing)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30).onEnded { value in
                    viewModel.handleDrag(translationWidth: value.translation.width, height: value.translation.height)
                }
            )
        }
        .ignoresSafeArea()
        .accessibilityElement()
        .accessibilityLabel(story.caption.map { Text($0) } ?? Text(L10n.Stories.photoOf(viewModel.city)))
        .accessibilityAddTraits(.isImage)
        .accessibilityAction(named: Text(L10n.Stories.next)) { viewModel.next() }
        .accessibilityAction(named: Text(L10n.Stories.previous)) { viewModel.previous() }
        .accessibilityIdentifier(AccessibilityID.Stories.page)
    }

    @ViewBuilder
    private var attribution: some View {
        if let name = story.photographerName {
            Text(L10n.Stories.attribution(name))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .shadow(radius: 3)
                .padding()
                .padding(.bottom, 24)
        }
    }
}

#Preview {
    StoriesView(viewModel: .preview)
}
