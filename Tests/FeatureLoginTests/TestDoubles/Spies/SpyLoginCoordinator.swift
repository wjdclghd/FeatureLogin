//
//  SpyLoginCoordinator.swift
//  FeatureLoginTests
//
//  Created by Codex on 5/11/26.
//

import AppDomain
@testable import FeatureLogin

@MainActor
final class SpyLoginCoordinator: LoginCoordinatorProtocol {
    private(set) var loginSucceededCallCount = 0
    private(set) var receivedSession: AuthSessionEntity?

    func loginSucceeded(session: AuthSessionEntity) {
        loginSucceededCallCount += 1
        receivedSession = session
    }
}
