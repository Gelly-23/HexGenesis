import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page = 0

    private let pages: [(title: String, subtitle: String, symbol: String)] = [
        ("结构", "先搭好棋盘：维度、网格、边界。", "square.grid.3x3.fill"),
        ("规则", "再写规则：演化、邻域、守恒与涌现。", "slider.horizontal.3"),
        ("开始", "从一次点击开始，让宇宙跑起来。", "sparkles")
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { idx in
                    VStack(spacing: 18) {
                        Spacer()

                        Image(systemName: pages[idx].symbol)
                            .font(.system(size: 80, weight: .regular))
                            .padding(.bottom, 10)

                        Text(pages[idx].title)
                            .font(.system(size: 34, weight: .bold))

                        Text(pages[idx].subtitle)
                            .font(.system(size: 17))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .opacity(0.85)

                        Spacer()

                        if idx == pages.count - 1 {
                            Button {
                                appState.hasSeenOnboarding = true
                            } label: {
                                Text("开始")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        } else {
                            Button {
                                withAnimation { page = min(page + 1, pages.count - 1) }
                            } label: {
                                Text("下一页")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.bordered)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        }
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                appState.hasSeenOnboarding = true
            } label: {
                Text("跳过")
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .padding(.trailing, 16)
            .padding(.top, 12)
        }
    }
}//
//  OnboardingView.swift
//  about life
//
//  Created by Gelly on 2025/12/12.
//

