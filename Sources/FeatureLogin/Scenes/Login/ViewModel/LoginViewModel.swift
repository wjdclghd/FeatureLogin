//
//  LoginViewModel.swift
//  FeatureLogin
//
//  Created by Codex on 5/11/26.
//

import Foundation
import Combine
import AppDomain

/// 로그인 화면의 상태와 사용자 intent를 관리합니다.
@MainActor
public final class LoginViewModel<
    LoginUseCase: LoginUseCaseProtocol,
    Coordinator: LoginCoordinatorProtocol
>: ObservableObject {
    @Published public private(set) var viewState: LoginViewState = .initial

    private let loginUseCase: LoginUseCase
    private let coordinator: Coordinator
    private var loginTask: Task<Void, Never>?

    /// LoginViewModel을 생성합니다.
    ///
    /// - Parameters:
    ///   - loginUseCase: 로그인 UseCase입니다.
    ///   - coordinator: 로그인 성공을 App 레이어에 전달하는 Coordinator입니다.
    public init(
        loginUseCase: LoginUseCase,
        coordinator: Coordinator
    ) {
        self.loginUseCase = loginUseCase
        self.coordinator = coordinator
    }

    deinit {
        loginTask?.cancel()
    }

    /// 이메일 입력 변경을 처리합니다.
    ///
    /// - Parameter email: 사용자가 입력한 이메일입니다.
    public func emailChanged(_ email: String) {
        viewState.email = email
        viewState.errorMessage = nil
    }

    /// 비밀번호 입력 변경을 처리합니다.
    ///
    /// - Parameter password: 사용자가 입력한 비밀번호입니다.
    public func passwordChanged(_ password: String) {
        viewState.password = password
        viewState.errorMessage = nil
    }

    /// 로그인 버튼 탭을 처리합니다.
    ///
    /// - Returns: 로그인 요청 비동기 작업입니다.
    @discardableResult
    public func loginButtonTapped() -> Task<Void, Never>? {
        submitLogin()
    }

    /// 비밀번호 입력 완료 액션을 처리합니다.
    ///
    /// - Returns: 로그인 요청 비동기 작업입니다.
    @discardableResult
    public func passwordSubmitTriggered() -> Task<Void, Never>? {
        submitLogin()
    }
}

private extension LoginViewModel {
    func submitLogin() -> Task<Void, Never>? {
        guard viewState.isLoginButtonEnabled else {
            return nil
        }

        let email = viewState.email
        let password = viewState.password
        viewState.isLoading = true
        viewState.errorMessage = nil

        let task = Task { [weak self, email, password] in
            guard let self else {
                return
            }

            await self.login(email: email, password: password)
        }
        loginTask = task
        return task
    }

    func login(email: String, password: String) async {
        do {
            let session = try await loginUseCase.execute(
                email: email,
                password: password
            )
            viewState.isLoading = false
            coordinator.loginSucceeded(session: session)
        } catch {
            viewState.isLoading = false
            viewState.errorMessage = errorMessage(from: error)
        }
    }

    func errorMessage(from error: Error) -> String {
        if let authDomainError = error as? AuthDomainError {
            return authDomainError.errorDescription ?? fallbackErrorMessage
        }

        return AuthDomainError.temporarilyUnavailable.errorDescription ?? fallbackErrorMessage
    }

    var fallbackErrorMessage: String {
        "로그인에 실패했습니다."
    }
}
