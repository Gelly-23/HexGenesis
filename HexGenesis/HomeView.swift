import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    
    @AppStorage("appLanguage") private var appLanguage: String = "zh-Hans"
      
    @State private var showGame = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Text("主页")
                    .font(.system(size: 34, weight: .bold))

                Button("进入游戏") {
                    showGame = true
                }
                .buttonStyle(.borderedProminent)

                Button("退出登录") {
                    appState.logout()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .navigationTitle("六边形宇宙")
            .fullScreenCover(isPresented: $showGame) {
                GameHostView(isPresented: $showGame)
            }
        }
    }
}
