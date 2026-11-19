//
//  Coordinator.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

/// A coordinator owns a navigation flow: it creates the flow's ViewModels,
/// listens to their navigation intents and mutates navigation state.
///
/// In SwiftUI the coordinator holds *state* (phase, path, presented sheet);
/// a companion `…CoordinatorView` renders that state. ViewModels never see a
/// coordinator type, only a narrow `…Navigating` protocol.
@MainActor
protocol Coordinator: AnyObject {
    func start() async
}
