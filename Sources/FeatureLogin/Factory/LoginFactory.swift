//
//  LoginFactory.swift
//  FeatureLogin
//
//  Created by jch on 5/5/26.
//

import SwiftUI

/// Login Feature 내부 화면 조립을 담당하는 factory입니다.
@MainActor
public struct LoginFactory {
    /// LoginFactory를 생성합니다.
    public init() { }

    /// Login root 화면을 생성합니다.
    ///
    /// - Parameter onLoginSuccess: 로그인 완료 후 App 레이어에 성공을 알리는 액션입니다.
    /// - Returns: Login root SwiftUI View입니다.
    public func makeLoginView(
        onLoginSuccess: @escaping @MainActor () -> Void
    ) -> some View {
        LoginView(onLoginSuccess: onLoginSuccess)
    }
}
