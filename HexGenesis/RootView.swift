import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    // 监听系统存储中的语言设置，默认简体中文
    @AppStorage("appLanguage") private var appLanguage: String = "zh-Hans"

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
        // 核心：强制覆盖当前视图树的环境语言
        .environment(\.locale, Locale(identifier: appLanguage))
    }
}
