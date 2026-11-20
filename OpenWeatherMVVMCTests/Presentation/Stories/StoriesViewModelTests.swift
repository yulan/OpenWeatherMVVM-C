//
//  StoriesViewModelTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
@testable import OpenWeatherMVVMC
import Testing

@MainActor
@Suite("StoriesViewModel")
struct StoriesViewModelTests {
    private let prefetcher = ImagePrefetcherSpy()

    private func makeSUT(
        _ result: Result<[Story], DomainError> = .success(Story.fixtures),
        city: String = "Paris"
    ) -> (StoriesViewModel, FetchCityStoriesUseCaseStub, StoriesNavigatorSpy) {
        let useCase = FetchCityStoriesUseCaseStub(result)
        let navigator = StoriesNavigatorSpy()
        let sut = StoriesViewModel(city: city, fetchStories: useCase, imagePrefetcher: prefetcher, storyDuration: .seconds(3))
        sut.navigator = navigator
        return (sut, useCase, navigator)
    }

    /// Loaded, with the first image on screen (timer running).
    private func makePlayingSUT(_ stories: [Story] = Story.fixtures) async -> StoriesViewModel {
        let (sut, _, _) = makeSUT(.success(stories))
        await sut.load()
        sut.markCurrentImageLoaded()
        return sut
    }

    // MARK: Loading

    @Test("Loads stories for the city")
    func loadsStories() async {
        let (sut, useCase, _) = makeSUT(city: "Lyon")

        await sut.load()

        #expect(useCase.requestedCities == ["Lyon"])
        #expect(sut.state == .loaded)
        #expect(sut.isPlaybackActive)
        #expect(sut.stories == Story.fixtures)
        #expect(sut.currentStory == Story.fixtures[0])
        #expect(sut.progress == 0)
        #expect(!sut.isCurrentStoryReady)
    }

    @Test("loadIfNeeded doesn't refetch once loaded")
    func loadIfNeeded() async {
        let (sut, useCase, _) = makeSUT()

        await sut.loadIfNeeded()
        await sut.loadIfNeeded()

        #expect(useCase.requestedCities.count == 1)
    }

    @Test("A failure exposes a retryable error and stops playback")
    func failure() async {
        let (sut, _, _) = makeSUT(.failure(.offline))

        await sut.load()

        #expect(sut.state == .failed(ErrorPresentation(.offline)!))
        #expect(sut.stories.isEmpty)
        #expect(!sut.isPlaybackActive)
    }

    @Test("An empty result is reported as an error, not a blank screen")
    func emptyResult() async {
        let (sut, _, _) = makeSUT(.success([]))

        await sut.load()

        guard case let .failed(presentation) = sut.state else {
            Issue.record("Expected failed state")
            return
        }
        #expect(presentation.recovery == .retry)
        #expect(presentation.symbol == .noPhotos)
    }

    @Test("play() returns immediately when there is nothing to play")
    func playWithoutStoriesReturns() async {
        let (sut, _, _) = makeSUT(.failure(.offline))
        await sut.load()

        await sut.play() // would hang forever if it ticked while failed

        #expect(sut.progress == 0)
    }

    // MARK: Image readiness

    @Test("The timer doesn't run until the current image is on screen")
    func waitsForImage() async {
        let (sut, _, _) = makeSUT()
        await sut.load()

        sut.advance(by: .seconds(10))
        #expect(sut.progress == 0)
        #expect(sut.currentIndex == 0)

        sut.markCurrentImageLoaded()
        sut.advance(by: .seconds(1.5))
        #expect(sut.progress == 0.5)
    }

    @Test("A late load callback for a story we already left is ignored")
    func lateImageCallbackIgnored() async {
        let sut = await makePlayingSUT()
        sut.next()

        sut.storyImageDidFinishLoading(Story.fixtures[0].id)

        #expect(!sut.isCurrentStoryReady)
    }

    @Test("Moving to another story waits for its image again")
    func newStoryWaitsForImage() async {
        let sut = await makePlayingSUT()

        sut.next()

        #expect(!sut.isCurrentStoryReady)
    }

    @Test("A single story keeps playing after wrapping (its image never reloads)")
    func singleStoryKeepsPlaying() async {
        let sut = await makePlayingSUT([.fixture("only")])

        sut.advance(by: .seconds(3)) // wraps onto itself
        sut.advance(by: .seconds(1.5))

        #expect(sut.currentIndex == 0)
        #expect(sut.progress == 0.5)
    }

    @Test("Previous on the first story restarts it without waiting for the image")
    func previousOnFirstStory() async {
        let sut = await makePlayingSUT()
        sut.advance(by: .seconds(1))

        sut.previous()

        #expect(sut.progress == 0)
        #expect(sut.isCurrentStoryReady)
    }

    // MARK: Navigation between stories

    @Test("Next advances and wraps around after the last story")
    func nextWraps() async {
        let sut = await makePlayingSUT()

        sut.next()
        #expect(sut.currentIndex == 1)
        sut.next()
        #expect(sut.currentIndex == 2)
        sut.next()
        #expect(sut.currentIndex == 0)
    }

    @Test("Previous goes back and stays on the first story")
    func previousClamps() async {
        let sut = await makePlayingSUT()

        sut.next()
        sut.next()
        sut.previous()
        #expect(sut.currentIndex == 1)
        sut.previous()
        sut.previous()
        #expect(sut.currentIndex == 0)
    }

    // MARK: Auto-advance

    @Test("Elapsed time accumulates progress then moves to the next story")
    func autoAdvance() async {
        let sut = await makePlayingSUT()

        sut.advance(by: .seconds(1))
        sut.advance(by: .seconds(1))
        #expect(abs(sut.progress - 2.0 / 3.0) < 0.0001)
        #expect(sut.currentIndex == 0)

        sut.advance(by: .seconds(1))
        #expect(sut.currentIndex == 1)
        #expect(sut.progress == 0)
    }

    @Test("Paused stories don't advance")
    func pausedDoesNotAdvance() async {
        let sut = await makePlayingSUT()

        sut.setPaused(true)
        sut.advance(by: .seconds(10))
        #expect(sut.progress == 0)

        sut.setPaused(false)
        sut.advance(by: .seconds(1.5))
        #expect(sut.progress == 0.5)
    }

    @Test("Per-bar progress reflects seen, current and upcoming stories")
    func perBarProgress() async {
        let sut = await makePlayingSUT()

        sut.next()
        sut.markCurrentImageLoaded()
        sut.advance(by: .seconds(1.5))

        #expect(sut.progress(forStoryAt: 0) == 1)
        #expect(sut.progress(forStoryAt: 1) == 0.5)
        #expect(sut.progress(forStoryAt: 2) == 0)
    }

    // MARK: Prefetching

    @Test("Once loaded, the second story's image is prefetched")
    func prefetchesSecondStoryOnLoad() async {
        let (sut, _, _) = makeSUT()

        await sut.load()

        #expect(prefetcher.prefetchedURLs == [Story.fixtures[1].imageURL])
    }

    @Test("Moving to a story prefetches the one after it, wrapping at the end")
    func prefetchesNextStory() async {
        let sut = await makePlayingSUT()

        sut.next()
        sut.next()

        #expect(prefetcher.prefetchedURLs == [1, 2, 0].map { Story.fixtures[$0].imageURL })
    }

    @Test("A single story prefetches nothing: it's already on screen")
    func singleStoryPrefetchesNothing() async {
        let sut = await makePlayingSUT([.fixture("only")])

        sut.next()

        #expect(prefetcher.prefetchedURLs.isEmpty)
    }

    @Test("A failed load prefetches nothing")
    func failedLoadPrefetchesNothing() async {
        let (sut, _, _) = makeSUT(.failure(.offline))

        await sut.load()

        #expect(prefetcher.prefetchedURLs.isEmpty)
    }

    // MARK: Gestures

    @Test("Tapping the left third goes back, elsewhere goes forward", arguments: [
        (0.0, 0), (0.32, 0), (0.34, 2), (0.9, 2),
    ])
    func tapZones(fraction: Double, expectedIndex: Int) async {
        let sut = await makePlayingSUT()
        sut.next() // index 1

        sut.handleTap(atHorizontalFraction: fraction)

        #expect(sut.currentIndex == expectedIndex)
    }

    @Test("Horizontal swipes navigate; short or diagonal-ish ones are ignored", arguments: [
        (-80.0, 10.0, 2),  // swipe left → next
        (80.0, -10.0, 0),  // swipe right → previous
        (-30.0, 0.0, 1),   // too short
        (-40.0, 60.0, 1),  // mostly vertical, below dismiss threshold
    ])
    func swipes(dx: Double, dy: Double, expectedIndex: Int) async {
        let sut = await makePlayingSUT()
        sut.next() // index 1

        sut.handleDrag(translationWidth: dx, height: dy)

        #expect(sut.currentIndex == expectedIndex)
    }

    @Test("Swiping down far enough closes the stories")
    func swipeDownCloses() {
        let (sut, _, navigator) = makeSUT()

        sut.handleDrag(translationWidth: 10, height: 150)

        #expect(navigator.closeCount == 1)
    }

    @Test("Close is forwarded to the navigator")
    func close() {
        let (sut, _, navigator) = makeSUT()

        sut.close()

        #expect(navigator.closeCount == 1)
    }
}

private extension StoriesViewModel {
    func markCurrentImageLoaded() {
        if let id = currentStory?.id { storyImageDidFinishLoading(id) }
    }
}
