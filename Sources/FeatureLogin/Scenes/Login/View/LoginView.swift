//
//  LoginView.swift
//  FeatureLogin
//
//  Created by jch on 4/28/26.
//

import SwiftUI
import AppDomain
import DesignSystem
import UIComponents

/// 로그인 화면입니다.
public struct LoginView<
    LoginUseCase: LoginUseCaseProtocol,
    Coordinator: LoginCoordinatorProtocol
>: View {
    @StateObject private var viewModel: LoginViewModel<LoginUseCase, Coordinator>
    @FocusState private var focusedField: FocusedField?

    /// LoginView를 생성합니다.
    ///
    /// - Parameter viewModel: 로그인 화면 상태와 intent를 관리하는 ViewModel입니다.
    public init(viewModel: LoginViewModel<LoginUseCase, Coordinator>) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()

            header

            inputFields
                .padding(.horizontal, DSSpacing.lg)

            if let errorMessage = viewModel.viewState.errorMessage {
                errorMessageView(errorMessage)
                    .padding(.horizontal, DSSpacing.lg)
            }

            PrimaryButton(
                title: "로그인",
                state: loginButtonState,
                size: .large
            ) {
                viewModel.loginButtonTapped()
            }
            .accessibilityIdentifier("login.submitButton")
            .padding(.horizontal, DSSpacing.lg)

            Spacer()
        }
        .padding(.vertical, DSSpacing.lg)
        .background(DSColor.background.ignoresSafeArea())
        .navigationTitle("")
        .onAppear {
            focusedField = .email
        }
    }
}

private extension LoginView {
    enum FocusedField: Hashable {
        case email
        case password
    }

    var header: some View {
        VStack(spacing: DSSpacing.md) {
            Text("Login")
                .font(DSTypography.display)
                .foregroundStyle(DSColor.textPrimary)

            Text("이메일과 비밀번호를 입력해 주세요")
                .font(DSTypography.body2)
                .foregroundStyle(DSColor.textSecondary)
        }
    }

    var inputFields: some View {
        VStack(spacing: DSSpacing.md) {
            TextField(
                "이메일",
                text: Binding(
                    get: { viewModel.viewState.email },
                    set: { viewModel.emailChanged($0) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
            .textContentType(.username)
            .submitLabel(.next)
            .focused($focusedField, equals: .email)
            .onSubmit {
                focusedField = .password
            }
            .font(DSTypography.body1)
            .foregroundStyle(DSColor.textPrimary)
            .padding(.horizontal, DSSpacing.md)
            .frame(height: 52)
            .background(DSColor.surface)
            .inputBorder()
            .accessibilityIdentifier("login.emailTextField")

            SecureField(
                "비밀번호",
                text: Binding(
                    get: { viewModel.viewState.password },
                    set: { viewModel.passwordChanged($0) }
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.password)
            .submitLabel(.go)
            .focused($focusedField, equals: .password)
            .onSubmit {
                viewModel.passwordSubmitTriggered()
            }
            .font(DSTypography.body1)
            .foregroundStyle(DSColor.textPrimary)
            .padding(.horizontal, DSSpacing.md)
            .frame(height: 52)
            .background(DSColor.surface)
            .inputBorder()
            .accessibilityIdentifier("login.passwordSecureField")
        }
    }

    func errorMessageView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: DSSpacing.xs) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(DSColor.error)

            Text(message)
                .font(DSTypography.caption1)
                .foregroundStyle(DSColor.error)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("login.errorMessage")
    }

    var loginButtonState: DSButtonState {
        if viewModel.viewState.isLoading {
            return .loading
        }

        return viewModel.viewState.isLoginButtonEnabled ? .normal : .disabled
    }
}
