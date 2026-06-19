import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 演化速度 (0.25 ~ 3.0)，默认 1.0
    @AppStorage("simulationSpeed") private var simulationSpeed: Double = 1.0
    
    var body: some View {
        NavigationStack {
            List {
                // 选项 1: 规则设定
                Section {
                    NavigationLink(destination: RuleSettingsView()) {
                        Label {
                            Text("规则设定")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("宇宙法则")
                }
                
                // 选项 2: 演化速度
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Label {
                                Text("演化速度")
                                    .font(.headline)
                            } icon: {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                            Text(String(format: "%.2fx", simulationSpeed))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        
                        // 速度滑块：0.25x 到 3.0x
                        HStack {
                            Image(systemName: "tortoise.fill")
                                .foregroundStyle(.secondary)
                            
                            Slider(value: $simulationSpeed, in: 0.25...3.0, step: 0.25) {
                                Text("Speed")
                            } minimumValueLabel: {
                                Text("0.25") .font(.caption2).hidden()
                            } maximumValueLabel: {
                                Text("3.0") .font(.caption2).hidden()
                            }
                            .onChangeCompat(of: simulationSpeed) { _ in
                                NotificationCenter.default.post(name: .speedChanged, object: nil)
                            }
                            
                            Image(systemName: "hare.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("时间流逝")
                } footer: {
                    Text("调整演化的快慢。1.0x 为标准速度。")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// 扩展通知名称
extension Notification.Name {
    static let speedChanged = Notification.Name("speedChanged")
}

#Preview {
    SettingsView()
}
