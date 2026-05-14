//
//  LoginViewState.swift
//  FeatureLogin
//
//  Created by Codex on 5/11/26.
//

import Foundation

/// 로그인 화면 렌더링 상태입니다.
public struct LoginViewState: Equatable, Sendable {
    /// 사용자가 입력한 이메일입니다.
    public var email: String

    /// 사용자가 입력한 비밀번호입니다.
    public var password: String

    /// 로그인 요청 중인지 여부입니다.
    public var isLoading: Bool

    /// 사용자에게 표시할 오류 메시지입니다.
    public var errorMessage: String?

    /// LoginViewState를 생성합니다.
    public init(
        email: String = "",
        password: String = "",
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.email = email
        self.password = password
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    /// 초기 상태입니다.
    public static let initial = LoginViewState()

    /// 로그인 버튼 활성화 여부입니다.
    public var isLoginButtonEnabled: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && password.isEmpty == false
            && isLoading == false
    }
}
