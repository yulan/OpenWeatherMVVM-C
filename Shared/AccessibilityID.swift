//
//  AccessibilityID.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

/// Accessibility identifiers shared by the app and the UI-test target
/// (this folder is compiled into both), so tests never match on wording.
enum AccessibilityID {
    enum Weather {
        static let header = "weather.header"
        static let storiesButton = "weather.storiesButton"
    }

    enum Stories {
        static let page = "stories.page"
        static let closeButton = "stories.closeButton"
    }

    enum ErrorState {
        static let view = "errorState.view"
        static let recoveryButton = "errorState.recoveryButton"
    }
}
