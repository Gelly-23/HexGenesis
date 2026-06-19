import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if !appState.hasSeenOnboarding {
                OnboardingView()
            } else if !appState.isLoggedIn {
                LoginView()
            } else {
                HomeView()
            }
        }
    }
}//
//  Untitled.swift
//  about life
//
//  Created by Gelly on 2025/12/12.
//

