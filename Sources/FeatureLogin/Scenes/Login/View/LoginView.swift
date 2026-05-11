//
//  LoginView.swift
//  FeatureLogin
//
//  Created by jch on 4/28/26.
//

import SwiftUI
import DesignSystem

struct LoginView: View {
    let onLoginSuccess: @MainActor () -> Void

    @State private var userID: String = ""
    @State private var password: String = ""

    private var isLoginEnabled: Bool {
        !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()

            VStack(spacing: DSSpacing.md) {
                Text("Login")
                    .font(DSTypography.display)

                Text("아이디와 비밀번호를 입력해 주세요")
                    .font(DSTypography.body2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: DSSpacing.md) {
                TextField("아이디", text: $userID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
                    .padding(.horizontal, DSSpacing.md)
                    .frame(height: 52)
                    .background(DSColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.md))

                SecureField("비밀번호", text: $password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                    .submitLabel(.go)
                    .padding(.horizontal, DSSpacing.md)
                    .frame(height: 52)
                    .background(DSColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.md))
            }
            .padding(.horizontal, DSSpacing.lg)

            Button {
                Task { @MainActor in
                    onLoginSuccess()
                }
            } label: {
                Text("로그인")
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColor.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isLoginEnabled ? DSColor.primary : DSColor.textDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: DSCornerRadius.md))
            }
            .disabled(!isLoginEnabled)
            .padding(.horizontal, DSSpacing.lg)

            Spacer()
        }
        .padding(.vertical, DSSpacing.lg)
        .navigationTitle("")
    }
}
