//
//  StubLoginUseCase.swift
//  FeatureLoginTests
//
//  Created by Codex on 5/11/26.
//

import AppDomain

final class StubLoginUseCase: LoginUseCaseProtocol, @unchecked Sendable {
    private(set) var executeCallCount = 0
    private(set) var receivedEmail: String?
    private(set) var receivedPassword: String?
    var stubbedResult: Result<AuthSessionEntity, Error> = .success(.fixture())
    var stubbedDelayNanoseconds: UInt64 = 0

    func execute(
        email: String,
        password: String
    ) async throws -> AuthSessionEntity {
        executeCallCount += 1
        receivedEmail = email
        receivedPassword = password

        if stubbedDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: stubbedDelayNanoseconds)
        }

        return try stubbedResult.get()
    }
}
