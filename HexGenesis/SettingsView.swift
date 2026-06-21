import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("simulationSpeed") private var simulationSpeed: Double = 1.0
    // 引入语言存储变量
    @AppStorage("appLanguage") private var appLanguage: String = "zh-Hans"
    
    var body: some View {
        NavigationStack {
            List {
                // 选项 0: 通用设置
                Section {
                    Picker(selection: $appLanguage) {
                        Text("简体中文").tag("zh-Hans")
                        Text("English").tag("en")
                    } label: {
                        Label {
                            Text("语言 / Language")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.indigo)
                        }
                    }
                } header: {
                    Text("通用 / General")
                }
                
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
                        
                        // 速度滑块
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

extension Notification.Name {
    static let speedChanged = Notification.Name("speedChanged")
}
