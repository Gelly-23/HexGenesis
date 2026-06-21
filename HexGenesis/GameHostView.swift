import SwiftUI

// 扩展 Notification 名称
extension Notification.Name {
    static let gameStart = Notification.Name("gameStart")
    static let gameReset = Notification.Name("gameReset")
    static let gameRecenter = Notification.Name("gameRecenter")
    static let drawModeChanged = Notification.Name("drawModeChanged")
    static let gameStep = Notification.Name("gameStep")
    // ❌ 删除：static let speedChanged = ... (因为其他文件已经定义了，这里不能重复)
}

struct GameHostView: View {
    @Binding var isPresented: Bool
    @State private var isPlaying = false
    @State private var showExitAlert = false
    @State private var showSettingsSheet = false
    @State private var isDrawMode = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. 底层：游戏画面
                GameViewControllerRepresentable()
                    .ignoresSafeArea()

                // 2. 顶层 UI 覆盖
                VStack {
                    // --- 顶部区域 ---
                    HStack {
                        // 退出按钮
                        Button { showExitAlert = true } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.6))
                                .shadow(radius: 2)
                        }
                        
                        Spacer()
                        
                        // 模式切换按钮 (右上角)
                        Button {
                            isDrawMode.toggle()
                            NotificationCenter.default.post(name: .drawModeChanged, object: nil, userInfo: ["isDrawMode": isDrawMode])
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isDrawMode ? "pencil.and.outline" : "hand.tap.fill")
                                Text(isDrawMode ? "添加" : "浏览")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(isDrawMode ? Color.blue.opacity(0.8) : Color.black.opacity(0.4))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // --- 底部控制岛 (悬浮胶囊) ---
                    HStack(spacing: 20) {
                        
                        // 1. 设置 (仅暂停可用)
                        controlButton(icon: "gearshape.fill", label: "设置", isEnabled: !isPlaying) {
                            showSettingsSheet = true
                        }
                        
                        // 2. 单步 (仅暂停可用)
                        controlButton(icon: "forward.frame.fill", label: "单步", isEnabled: !isPlaying) {
                            NotificationCenter.default.post(name: .gameStep, object: nil)
                        }
                        
                        // 3. 复位 (随时可用)
                        controlButton(icon: "scope", label: "复位", isEnabled: true) {
                            NotificationCenter.default.post(name: .gameRecenter, object: nil)
                        }
                        
                        // 4. 重置 (仅暂停可用)
                        controlButton(icon: "arrow.counterclockwise", label: "重置", isEnabled: !isPlaying) {
                            NotificationCenter.default.post(name: .gameReset, object: nil)
                        }
                        
                        // 5. 播放/暂停 (主按钮)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isPlaying.toggle()
                            }
                            NotificationCenter.default.post(name: .gameStart, object: nil)
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(isPlaying ? .white : .black)
                                .frame(width: 56, height: 56)
                                .background(isPlaying ? Color.orange : Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                    .padding(.bottom, 40)
                }
            }
            .alert("确定要退出吗？", isPresented: $showExitAlert) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) { isPresented = false }
            } message: {
                Text("退出后当前的演化进度将会丢失。")
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
        }
    }
    
    // MARK: - 辅助组件
    private func controlButton(icon: String, label: LocalizedStringKey, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isEnabled ? .white.opacity(0.9) : .white.opacity(0.3))
            .frame(width: 50, height: 50)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
    }
}

struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController { GameViewController() }
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}
