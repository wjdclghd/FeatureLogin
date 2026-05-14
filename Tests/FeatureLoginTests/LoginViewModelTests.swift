//
//  LoginViewModelTests.swift
//  FeatureLoginTests
//
//  Created by Codex on 5/11/26.
//

import XCTest
import AppDomain
@testable import FeatureLogin

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: LoginViewModel<StubLoginUseCase, SpyLoginCoordinator>!
    private var loginUseCase: StubLoginUseCase!
    private var coordinator: SpyLoginCoordinator!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        loginUseCase = StubLoginUseCase()
        coordinator = SpyLoginCoordinator()
        sut = LoginViewModel(
            loginUseCase: loginUseCase,
            coordinator: coordinator
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        loginUseCase = nil
        coordinator = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_initialState_disablesLoginButton() {
        XCTAssertEqual(sut.viewState, .initial)
        XCTAssertFalse(sut.viewState.isLoginButtonEnabled)
    }

    func test_emailAndPasswordChanged_updatesInputAndEnablesLoginButton() {
        sut.emailChanged("test@example.com")
        sut.passwordChanged("password123")

        XCTAssertEqual(sut.viewState.email, "test@example.com")
        XCTAssertEqual(sut.viewState.password, "password123")
        XCTAssertTrue(sut.viewState.isLoginButtonEnabled)
    }

    func test_loginButtonTapped_withValidInput_callsUseCaseAndCoordinator() async {
        let expectedSession = AuthSessionEntity.fixture()
        loginUseCase.stubbedResult = .success(expectedSession)
        sut.emailChanged("test@example.com")
        sut.passwordChanged("password123")

        let task = sut.loginButtonTapped()
        await task?.value

        XCTAssertEqual(loginUseCase.executeCallCount, 1)
        XCTAssertEqual(loginUseCase.receivedEmail, "test@example.com")
        XCTAssertEqual(loginUseCase.receivedPassword, "password123")
        XCTAssertEqual(coordinator.loginSucceededCallCount, 1)
        XCTAssertEqual(coordinator.receivedSession, expectedSession)
        XCTAssertFalse(sut.viewState.isLoading)
        XCTAssertNil(sut.viewState.errorMessage)
    }

    func test_loginButtonTapped_whenUseCaseThrows_setsErrorMessageAndDoesNotCallCoordinator() async {
        loginUseCase.stubbedResult = .failure(AuthDomainError.invalidCredentials)
        sut.emailChanged("test@example.com")
        sut.passwordChanged("wrong-password")

        let task = sut.loginButtonTapped()
        await task?.value

        XCTAssertEqual(loginUseCase.executeCallCount, 1)
        XCTAssertEqual(coordinator.loginSucceededCallCount, 0)
        XCTAssertEqual(sut.viewState.errorMessage, AuthDomainError.invalidCredentials.errorDescription)
        XCTAssertFalse(sut.viewState.isLoading)
    }

    func test_loginButtonTapped_whileLoading_doesNotStartDuplicateRequest() async {
        loginUseCase.stubbedDelayNanoseconds = 100_000_000
        sut.emailChanged("test@example.com")
        sut.passwordChanged("password123")

        let firstTask = sut.loginButtonTapped()
        let secondTask = sut.loginButtonTapped()

        await firstTask?.value
        await secondTask?.value

        XCTAssertEqual(loginUseCase.executeCallCount, 1)
    }

    func test_inputChanged_clearsErrorMessage() async {
        loginUseCase.stubbedResult = .failure(AuthDomainError.invalidEmail)
        sut.emailChanged("invalid")
        sut.passwordChanged("password123")

        let task = sut.loginButtonTapped()
        await task?.value

        XCTAssertNotNil(sut.viewState.errorMessage)

        sut.emailChanged("test@example.com")

        XCTAssertNil(sut.viewState.errorMessage)
    }
}
