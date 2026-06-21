import SwiftUI

struct RuleSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("rule_limitLower") private var limitLower: Int = 5
    @AppStorage("rule_limitUpper") private var limitUpper: Int = 9
    
    private let maxEnergy = 18
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {//底部留空间
                
                // 顶部说明图示 (将数字和汉字拆开传递)
                HStack(spacing: 0) {
                    ruleBlock(color: .gray, range: "0 ~ \(limitLower)", label: "衰变")
                    Image(systemName: "arrow.right")
                    ruleBlock(color: .green, range: "\(limitLower + 1) ~ \(limitUpper)", label: "生长")
                    Image(systemName: "arrow.right")
                    ruleBlock(color: .red, range: "> \(limitUpper)", label: "过载")
                }
                .padding(.top, 20)
                
                Divider()
                
                // 滚轮选择区
                HStack(spacing: 0) {
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
                            if newValue >= limitUpper { limitUpper = min(newValue + 1, 18) }
                        }
                    }
                    
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
                            if newValue <= limitLower { limitLower = max(newValue - 1, 0) }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Text("“邻居能量总和”决定了格子的命运。\n调整这两个数值，创造不同的宇宙法则。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true) // 核心修复：强制垂直方向完整换行展开，绝不截断
                    .padding(.horizontal, 24) // 增加左右边距
                    .padding(.bottom, 20)     // 增加底部边距，防止被 iPhone 底部的横条遮挡
            }
            .navigationTitle("演化规则设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        NotificationCenter.default.post(name: .rulesChanged, object: nil)
                        dismiss()
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .presentationDetents([.medium])
    }
    
    // 辅助视图：修改参数接收方式，使 Text("衰变") 被系统识别为翻译键值
    private func ruleBlock(color: Color, range: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(range)
            Text(label)
        }
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

extension View {
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in action(newValue) }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}

extension Notification.Name {
    static let rulesChanged = Notification.Name("rulesChanged")
}
