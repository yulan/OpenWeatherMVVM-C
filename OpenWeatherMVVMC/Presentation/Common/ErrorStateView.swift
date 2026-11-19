//
//  ErrorStateView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

/// Full-screen error used by every feature (was duplicated per screen).
struct ErrorStateView: View {
    let error: ErrorPresentation
    let onRecover: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(error.title)
            } icon: {
                Image(symbol: error.symbol)
            }
        } description: {
            Text(error.message)
        } actions: {
            Button(error.recovery.title, action: onRecover)
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))
                .accessibilityIdentifier(AccessibilityID.ErrorState.recoveryButton)
        }
        // Always drawn on a dark/saturated background: force a readable
        // palette regardless of the system appearance.
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        // `.contain` keeps the identifier on the container; without it the
        // identifier propagates to every child and hides the button's own.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.ErrorState.view)
    }
}
