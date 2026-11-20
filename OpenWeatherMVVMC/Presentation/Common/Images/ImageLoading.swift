//
//  ImageLoading.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
import UIKit

/// What a view needs to show a remote image.
protocol ImageLoading: Sendable {
    /// Synchronous memory lookup, so an already-loaded image is drawn on the
    /// very first frame instead of flashing a spinner.
    func cachedImage(for url: URL) -> UIImage?
    func image(for url: URL) async throws -> UIImage
}

/// What a ViewModel needs to warm the cache. Deliberately URL-only: the
/// ViewModel never touches `UIImage`.
protocol ImagePrefetching: Sendable {
    /// Fire-and-forget. The loader owns the work, so it outlives the caller.
    func prefetch(_ urls: [URL])
}
