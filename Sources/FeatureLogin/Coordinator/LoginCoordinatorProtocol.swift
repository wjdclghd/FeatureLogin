//
//  LoginCoordinatorProtocol.swift
//  FeatureLogin
//
//  Created by Codex on 5/11/26.
//

import AppDomain

/// 로그인 화면에서 App 레이어로 전달하는 화면 이동 계약입니다.
@MainActor
public protocol LoginCoordinatorProtocol: AnyObject {
    /// 로그인 성공을 App 레이어에 알립니다.
    ///
    /// - Parameter session: 로그인 UseCase가 반환한 인증 세션입니다.
    func loginSucceeded(session: AuthSessionEntity)
}
