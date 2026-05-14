//
//  AuthSessionEntity+Fixture.swift
//  FeatureLoginTests
//
//  Created by Codex on 5/11/26.
//

import Foundation
import AppDomain

extension AuthSessionEntity {
    static func fixture(
        token: AuthTokenEntity = .fixture(),
        user: AuthenticatedUserEntity = .fixture()
    ) -> AuthSessionEntity {
        AuthSessionEntity(token: token, user: user)
    }
}

extension AuthTokenEntity {
    static func fixture(
        accessToken: String = "access-token",
        refreshToken: String = "refresh-token",
        accessTokenExpiresAt: Date = Date(timeIntervalSince1970: 900),
        refreshTokenExpiresAt: Date = Date(timeIntervalSince1970: 1_209_600)
    ) -> AuthTokenEntity {
        AuthTokenEntity(
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessTokenExpiresAt: accessTokenExpiresAt,
            refreshTokenExpiresAt: refreshTokenExpiresAt
        )
    }
}

extension AuthenticatedUserEntity {
    static func fixture(
        userId: Int = 1,
        email: String = "test@example.com",
        nickname: String = "jch",
        role: String = "USER",
        status: String = "ACTIVE"
    ) -> AuthenticatedUserEntity {
        AuthenticatedUserEntity(
            userId: userId,
            email: email,
            nickname: nickname,
            role: role,
            status: status
        )
    }
}
