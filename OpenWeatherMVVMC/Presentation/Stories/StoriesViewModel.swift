//
//  StoriesViewModel.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation
import Observation

/// Instagram-style auto-advancing stories.
///
/// Timing is split from logic: `play()` only sleeps on an injected clock and
/// calls `advance(by:)`, a pure state transition that is unit-tested directly.
/// Gesture *decisions* (which third was tapped, which way was swiped) also
/// live here; the view only reports raw geometry.
@MainActor
@Observable
final class StoriesViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case failed(ErrorPresentation)
    }

    static let previousTapZone = 1.0 / 3.0
    static let minimumSwipeDistance = 50.0
    static let dismissSwipeDistance = 100.0

    let city: String
    private(set) var state: State = .loading
    private(set) var stories: [Story] = []
    private(set) var currentIndex = 0
    /// Progress of the current story, 0...1.
    private(set) var progress: Double = 0
    private(set) var isPaused = false
    /// The timer only runs once the current image is on screen, so a slow
    /// network never skips a story the user hasn't seen.
    private(set) var isCurrentStoryReady = false

    weak var navigator: (any StoriesNavigating)?

    @ObservationIgnored private let storyDuration: Duration
    @ObservationIgnored private let tick: Duration
    @ObservationIgnored private let clock: any Clock<Duration>
    @ObservationIgnored private let fetchStories: any FetchCityStoriesUseCase

    init(
        city: String,
        fetchStories: any FetchCityStoriesUseCase,
        storyDuration: Duration = .seconds(3),
        tick: Duration = .milliseconds(50),
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.city = city
        self.fetchStories = fetchStories
        self.storyDuration = storyDuration
        self.tick = tick
        self.clock = clock
    }

    var currentStory: Story? {
        stories.indices.contains(currentIndex) ? stories[currentIndex] : nil
    }

    /// Drives `.task(id:)` in the view: playback exists only while loaded.
    var isPlaybackActive: Bool { state == .loaded }

    // MARK: - Loading

    func loadIfNeeded() async {
        guard state != .loaded else { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            let stories = try await fetchStories.execute(city: city)
            self.stories = stories
            currentIndex = 0
            progress = 0
            isCurrentStoryReady = false
            state = stories.isEmpty
                ? .failed(ErrorPresentation(L10n.Stories.emptyTitle, L10n.Stories.emptyMessage(city), .noPhotos, .retry))
                : .loaded
        } catch {
            stories = []
            if let presentation = ErrorPresentation(error) {
                state = .failed(presentation)
            }
        }
    }

    // MARK: - Playback

    /// Returns immediately unless loaded; otherwise ticks until cancelled.
    func play() async {
        guard isPlaybackActive else { return }
        while !Task.isCancelled {
            do {
                try await clock.sleep(for: tick)
            } catch {
                return
            }
            advance(by: tick)
        }
    }

    func advance(by elapsed: Duration) {
        guard state == .loaded, !isPaused, isCurrentStoryReady, !stories.isEmpty else { return }
        progress = min(progress + elapsed / storyDuration, 1)
        if progress >= 1 { next() }
    }

    func storyImageDidFinishLoading(_ id: Story.ID) {
        guard currentStory?.id == id else { return } // a late callback for a story we already left
        isCurrentStoryReady = true
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
    }

    // MARK: - Navigation between stories

    /// Wraps around to the first story after the last one.
    func next() {
        guard !stories.isEmpty else { return }
        show(index: (currentIndex + 1) % stories.count)
    }

    /// On the first story, restarts it.
    func previous() {
        guard !stories.isEmpty else { return }
        show(index: max(currentIndex - 1, 0))
    }

    private func show(index: Int) {
        progress = 0
        // Same index (single story, or "previous" on the first one): the image
        // is already on screen and won't report loading again.
        guard index != currentIndex else { return }
        currentIndex = index
        isCurrentStoryReady = false
    }

    // MARK: - Gestures

    /// - Parameter fraction: tap x-position divided by the view width.
    func handleTap(atHorizontalFraction fraction: Double) {
        fraction < Self.previousTapZone ? previous() : next()
    }

    func handleDrag(translationWidth dx: Double, height dy: Double) {
        if abs(dx) > abs(dy) {
            guard abs(dx) >= Self.minimumSwipeDistance else { return }
            dx < 0 ? next() : previous()
        } else if dy >= Self.dismissSwipeDistance {
            close()
        }
    }

    func close() {
        navigator?.closeStories()
    }

    /// Fill of the bar at `index`: full for seen stories, partial for the
    /// current one, empty for upcoming ones.
    func progress(forStoryAt index: Int) -> Double {
        if index < currentIndex { 1 } else if index == currentIndex { progress } else { 0 }
    }
}
