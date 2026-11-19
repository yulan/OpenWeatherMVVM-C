//
//  SplashView.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

/// Purely visual: *when* it disappears is the AppCoordinator's decision.
struct SplashView: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(symbol: .appLogo)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 96))
                .scaleEffect(isVisible ? 1 : 0.8)
                .opacity(isVisible ? 1 : 0.5)
                .accessibilityHidden(true)
            Text(L10n.Splash.title)
                .font(.largeTitle.bold())
                .foregroundStyle(Color(.brand))
            Spacer()
            Text(L10n.Splash.poweredBy)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { isVisible = true }
        }
    }
}

#Preview("Light") { SplashView() }
#Preview("Dark") { SplashView().preferredColorScheme(.dark) }
