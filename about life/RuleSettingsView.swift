import SwiftUI

struct RuleSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 使用 UserDefaults 直接读写
    @AppStorage("rule_limitLower") private var limitLower: Int = 5
    @AppStorage("rule_limitUpper") private var limitUpper: Int = 9
    
    // 最大能量参考值 (6邻居*3能量=18)
    private let maxEnergy = 18
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                // 顶部说明图示
                HStack(spacing: 0) {
                    ruleBlock(color: .gray, text: "0 ~ \(limitLower)\n衰变")
                    Image(systemName: "arrow.right")
                    ruleBlock(color: .green, text: "\(limitLower + 1) ~ \(limitUpper)\n生长")
                    Image(systemName: "arrow.right")
                    ruleBlock(color: .red, text: "> \(limitUpper)\n过载")
                }
                .padding(.top, 20)
                
                Divider()
                
                // 滚轮选择区
                HStack(spacing: 0) {
                    // 左边滚轮：衰变/生长临界值 (范围 0-17)
                    VStack {
                        Text("衰变 / 生长")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Picker("", selection: $limitLower) {
                            ForEach(0...17, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .onChangeCompat(of: limitLower) { newValue in
                            // 逻辑约束：下限必须小于上限
                            if newValue >= limitUpper {
                                limitUpper = min(newValue + 1, 18)
                            }
                        }
                    }
                    
                    // 右边滚轮：生长/过载临界值 (范围 3-18)
                    VStack {
                        Text("生长 / 过载")
                            .font(.headline)
                            .foregroundColor(.green)
                        Picker("", selection: $limitUpper) {
                            ForEach(3...18, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .onChangeCompat(of: limitUpper) { newValue in
                            // 逻辑约束：上限必须大于下限
                            if newValue <= limitLower {
                                limitLower = max(newValue - 1, 0)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("“邻居能量总和”决定了格子的命运。\n调整这两个数值，创造不同的宇宙法则。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("演化规则设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        // 发送通知告诉 GameScene 刷新规则
                        NotificationCenter.default.post(name: .rulesChanged, object: nil)
                        dismiss()
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .presentationDetents([.medium])
    }
    
    // 辅助视图
    private func ruleBlock(color: Color, text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
            .padding(.horizontal, 4)
    }
}

// iOS 16/17 兼容
extension View {
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}

// 扩展通知名称
extension Notification.Name {
    static let rulesChanged = Notification.Name("rulesChanged")
}

#Preview {
    RuleSettingsView()
}
