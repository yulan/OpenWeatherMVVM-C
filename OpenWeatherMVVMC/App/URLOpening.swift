//
//  URLOpening.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import UIKit

/// Abstraction over `UIApplication.open` so coordinators stay unit-testable.
@MainActor
protocol URLOpening {
    func open(_ url: URL)
}

struct SystemURLOpener: URLOpening {
    func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
