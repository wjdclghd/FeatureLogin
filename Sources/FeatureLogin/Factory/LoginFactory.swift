//
//  LoginFactory.swift
//  FeatureLogin
//
//  Created by jch on 5/5/26.
//

import SwiftUI
import AppDomain

/// Login Feature 내부 화면 조립을 담당하는 factory입니다.
@MainActor
public struct LoginFactory {
    /// LoginFactory를 생성합니다.
    public init() { }

    /// Login root 화면을 생성합니다.
    ///
    /// - Parameters:
    ///   - useCase: 로그인에 사용할 UseCase입니다.
    ///   - coordinator: 로그인 성공을 App 레이어에 전달하는 Coordinator입니다.
    /// - Returns: Login root SwiftUI View입니다.
    public func makeLoginView<
        UseCase: LoginUseCaseProtocol,
        Coordinator: LoginCoordinatorProtocol
    >(
        useCase: UseCase,
        coordinator: Coordinator
    ) -> LoginView<UseCase, Coordinator> {
        let viewModel = LoginViewModel(
            loginUseCase: useCase,
            coordinator: coordinator
        )

        return LoginView(viewModel: viewModel)
    }
}
