import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Text("登录")
                    .font(.system(size: 34, weight: .bold))

                Text("初版：假登录（本地标记）。后续再接真实账号体系。")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(0.8)

                VStack(spacing: 12) {
                    TextField("用户名（可随便填）", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("密码（可随便填）", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Button {
                    appState.isLoggedIn = true
                } label: {
                    Text("登录")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}//
//  LoginView.swift
//  about life
//
//  Created by Gelly on 2025/12/12.
//

