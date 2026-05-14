# FeatureLogin Module

Clean Architecture + MVVM 환경에서 App 타겟이 SPM 모듈로 의존하는 형태를 전제로 만든 FeatureLogin 모듈입니다.
이 모듈은 **로그인 화면 기능(Login Feature)** 역할에 집중하며, 이메일/비밀번호 기반 로그인 흐름을 외부 의존성에 노출하지 않고 **공개 Factory + 공개 계약 + 내부 ViewModel/View**로 역할을 분리합니다.

모듈 내부는 이메일·비밀번호 입력, 중복 요청 방지, UseCase 호출, Coordinator 위임 기능을 포함하며,
상위 계층은 `LoginFactory.makeLoginView(useCase:coordinator:)`를 통해 `LoginView`를 즉시 조립할 수 있습니다.

**요약**
- 화면 조립 진입점: `LoginFactory`
- 공개 계약: `LoginCoordinatorProtocol`
- 상태 모델: `LoginViewState`
- ViewModel: `LoginViewModel<LoginUseCase, Coordinator>`
- View: `LoginView<LoginUseCase, Coordinator>`
- 의존 UseCase Protocol: `LoginUseCaseProtocol` (AppDomain)
- 의존 도메인 모델: `AuthSessionEntity`, `AuthDomainError` (AppDomain)
- 디자인 토큰: `DesignSystem` (`DSColor`, `DSTypography`, `DSSpacing`)
- UI 컴포넌트: `UIComponents` (`PrimaryButton`, `DSButtonState`)

---

**모듈 구조**
```text
FeatureLogin/
├─ Package.swift
├─ Sources/
│  └─ FeatureLogin/
│     ├─ Coordinator/
│     │  └─ LoginCoordinatorProtocol.swift
│     ├─ Factory/
│     │  └─ LoginFactory.swift
│     └─ Scenes/
│        └─ Login/
│           ├─ View/
│           │  └─ LoginView.swift
│           └─ ViewModel/
│              ├─ LoginViewModel.swift
│              └─ LoginViewState.swift
└─ Tests/
   └─ FeatureLoginTests/
      ├─ LoginViewModelTests.swift
      └─ TestDoubles/
         ├─ Fixtures/
         │  └─ AuthSessionEntity+Fixture.swift
         ├─ Spies/
         │  └─ SpyLoginCoordinator.swift
         └─ Stubs/
            └─ StubLoginUseCase.swift
```

---

**빠른 시작**

`LoginFactory.makeLoginView(useCase:coordinator:)`는 조립이 완료된 `LoginView`를 즉시 반환합니다.

```swift
import FeatureLogin

let factory = LoginFactory()
let view = factory.makeLoginView(
    useCase: container.makeLoginUseCase(),
    coordinator: accountNavigator
)
```

App Target의 `RouteBuilder`에서 아래처럼 사용합니다.

```swift
@MainActor
struct AccountRouteBuilder {
    private let container: DIContainer

    func makeRootView(navigator: AccountNavigator) -> AnyView {
        let factory = LoginFactory()
        return AnyView(
            factory.makeLoginView(
                useCase: container.makeLoginUseCase(),
                coordinator: navigator
            )
        )
    }
}
```

Preview나 테스트처럼 실제 UseCase 없이 화면만 확인하는 환경에서는 Stub을 주입합니다.

```swift
import FeatureLogin

let factory = LoginFactory()
let view = factory.makeLoginView(
    useCase: StubLoginUseCase(),
    coordinator: PreviewLoginCoordinator()
)
```

---

**핵심 설계 방향**

- **Feature 경계 내 역할 분리**
  상위 계층(App Target)은 `LoginFactory`, `LoginCoordinatorProtocol`, `LoginView`만 의존합니다.
  `LoginViewModel`, `LoginViewState`, `FocusedField` 같은 내부 구현 세부는 ViewModel/View 레이어 안에 감춥니다.

- **제네릭 DI 기반 조립**
  `LoginView<UseCase, Coordinator>`와 `LoginViewModel<UseCase, Coordinator>`는 제네릭 의존성을 주입받습니다.
  `any` protocol existential 저장 없이 컴파일 타임 타입 안전성을 확보합니다.

- **단방향 상태 흐름**
  View는 `viewModel.viewState`를 읽고 Intent 메서드만 호출합니다.
  `viewState`를 View가 직접 수정하지 않습니다.

- **중복 요청 방지**
  `loginTask`로 진행 중인 로그인 Task를 추적하고, `isLoginButtonEnabled`가 false인 동안 재호출을 차단합니다.

- **Coordinator 위임**
  로그인 성공 후 화면 이동 결정은 Feature 내부에서 하지 않습니다.
  `LoginCoordinatorProtocol.loginSucceeded(session:)` 호출로 App Target에 위임합니다.

- **테스트 친화적인 구조**
  ViewModel이 `LoginUseCaseProtocol`과 `LoginCoordinatorProtocol`만 알므로 Stub/Spy TestDouble 대체가 용이합니다.
  모든 Intent는 `Task<Void, Never>?`를 반환해 비동기 테스트에서 완료를 보장합니다.

---

**LoginCoordinatorProtocol**

`LoginCoordinatorProtocol`은 Feature ViewModel이 App 레이어로 로그인 성공을 전달하는 공개 계약입니다.

```swift
@MainActor
public protocol LoginCoordinatorProtocol: AnyObject {
    func loginSucceeded(session: AuthSessionEntity)
}
```

App Target의 `AccountNavigator`가 이 프로토콜을 구현하고 실제 화면 전환을 수행합니다.

---

**LoginFactory**

`LoginFactory`는 FeatureLogin 모듈의 **화면 조립 진입점(composition entry point)** 입니다.

제공 메서드:
- `makeLoginView(useCase:coordinator:)` — 제네릭 UseCase와 Coordinator를 주입받아 `LoginView`를 반환

```swift
let factory = LoginFactory()
let view = factory.makeLoginView(
    useCase: container.makeLoginUseCase(),
    coordinator: navigator
)
```

Factory는 내부적으로 `LoginViewModel`을 생성하고 `LoginView`에 주입합니다.
UseCase, Repository, DataSource 생성은 담당하지 않습니다. 외부에서 받은 구현체를 조립합니다.

---

**LoginViewModel**

`LoginViewModel`은 로그인 화면의 상태와 사용자 Intent를 관리합니다.

```swift
@MainActor
public final class LoginViewModel<
    LoginUseCase: LoginUseCaseProtocol,
    Coordinator: LoginCoordinatorProtocol
>: ObservableObject {

    // MARK: - Output

    @Published public private(set) var viewState: LoginViewState = .initial

    // MARK: - Dependencies

    private let loginUseCase: LoginUseCase
    private let coordinator: Coordinator
    private var loginTask: Task<Void, Never>?

    // MARK: - Intent

    public func emailChanged(_ email: String)
    public func passwordChanged(_ password: String)

    @discardableResult
    public func loginButtonTapped() -> Task<Void, Never>?

    @discardableResult
    public func passwordSubmitTriggered() -> Task<Void, Never>?
}
```

**Intent 처리 흐름:**
- `emailChanged(_:)` / `passwordChanged(_:)` — `viewState` 갱신, `errorMessage` nil 초기화
- `loginButtonTapped()` / `passwordSubmitTriggered()` — `isLoginButtonEnabled` 확인 후 `submitLogin()` 진행
- `submitLogin()` — `isLoading = true`, `loginUseCase.execute(email:password:)` 비동기 호출
- 성공 시 `coordinator.loginSucceeded(session:)` 위임
- 실패 시 `viewState.errorMessage` 갱신 (AuthDomainError 기반 메시지 변환)

---

**LoginViewState**

`LoginViewState`는 ViewModel이 View에 노출하는 로그인 화면 상태 전체를 하나의 타입으로 묶은 구조체입니다.

```swift
public struct LoginViewState: Equatable, Sendable {
    public var email: String
    public var password: String
    public var isLoading: Bool
    public var errorMessage: String?

    public static let initial = LoginViewState()

    public var isLoginButtonEnabled: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && password.isEmpty == false
            && isLoading == false
    }
}
```

| 프로퍼티 | 타입 | 역할 |
|---|---|---|
| `email` | `String` | 사용자 이메일 입력값 |
| `password` | `String` | 사용자 비밀번호 입력값 |
| `isLoading` | `Bool` | 로그인 요청 진행 중 여부 |
| `errorMessage` | `String?` | 화면에 표시할 오류 메시지 |
| `isLoginButtonEnabled` | `Bool` (computed) | 로그인 버튼 활성화 여부 |

---

**LoginView**

`LoginView`는 로그인 화면 렌더링만 담당합니다.

```swift
public struct LoginView<
    LoginUseCase: LoginUseCaseProtocol,
    Coordinator: LoginCoordinatorProtocol
>: View {
    @StateObject private var viewModel: LoginViewModel<LoginUseCase, Coordinator>
    @FocusState private var focusedField: FocusedField?
}
```

**사용 컴포넌트:**

| 컴포넌트 | 출처 | 역할 |
|---|---|---|
| `Text` | SwiftUI | 헤더 제목 · 서브타이틀 |
| `TextField` | SwiftUI | 이메일 입력 (emailAddress 키보드, submitLabel .next) |
| `SecureField` | SwiftUI | 비밀번호 입력 (submitLabel .go) |
| `PrimaryButton` | UIComponents | 로그인 버튼 (loading / disabled / normal 상태) |

**사용 디자인 토큰:**

| 토큰 | 용도 |
|---|---|
| `DSColor.background` | 화면 배경 |
| `DSColor.surface` | 입력 필드 배경 |
| `DSColor.textPrimary` | 입력 텍스트 |
| `DSColor.textSecondary` | 서브타이틀 텍스트 |
| `DSColor.error` | 에러 메시지 색상 |
| `DSTypography.display` | "Login" 헤더 폰트 |
| `DSTypography.body1` | 입력 필드 폰트 |
| `DSTypography.body2` | 서브타이틀 폰트 |
| `DSTypography.caption1` | 에러 메시지 폰트 |
| `DSSpacing.lg` | 수평 패딩, 섹션 간격 |
| `DSSpacing.md` | 입력 필드 내부 패딩, 필드 간격 |
| `DSSpacing.xs` | 에러 아이콘 ↔ 텍스트 간격 |

**Accessibility Identifier:**

| 식별자 | 요소 |
|---|---|
| `login.emailTextField` | 이메일 입력 필드 |
| `login.passwordSecureField` | 비밀번호 입력 필드 |
| `login.submitButton` | 로그인 버튼 |
| `login.errorMessage` | 에러 메시지 영역 |

---

**공개 모델과 계약**

### FeatureLogin 공개 타입

| 타입 | 종류 | 역할 |
|---|---|---|
| `LoginCoordinatorProtocol` | Protocol | Feature → App 네비게이션 계약 |
| `LoginFactory` | Struct | View / ViewModel 조립 진입점 |
| `LoginView<UseCase, Coordinator>` | Generic Struct | 로그인 SwiftUI View |
| `LoginViewModel<UseCase, Coordinator>` | Generic Class | 로그인 상태 · Intent 관리 |
| `LoginViewState` | Struct | 화면 렌더링 상태 모델 |

### AppDomain에서 가져오는 타입

| 타입 | 종류 | 역할 |
|---|---|---|
| `LoginUseCaseProtocol` | Protocol | 로그인 비즈니스 로직 계약 |
| `AuthSessionEntity` | Struct | 로그인 성공 결과 (token + user) |
| `AuthTokenEntity` | Struct | Access / Refresh 토큰 |
| `AuthenticatedUserEntity` | Struct | 인증된 사용자 정보 |
| `AuthDomainError` | Enum | 인증 도메인 에러 |

---

**의존성 구조**

```text
App Target (DIContainer, AccountRouteBuilder, AccountNavigator)
    │
    │ depends on
    ▼
FeatureLogin
    │
    ├─ depends on AppDomain    (LoginUseCaseProtocol, AuthSessionEntity, AuthDomainError)
    ├─ depends on DesignSystem (DSColor, DSTypography, DSSpacing)
    └─ depends on UIComponents (PrimaryButton, DSButtonState)
```

**FeatureLogin이 직접 import하지 않는 것:**

| 대상 | 이유 |
|---|---|
| `AppData` | Repository, DataSource, DTO, Mapper는 App Target이 조립 |
| `Networking` | Infrastructure는 AppData 계층 책임 |
| `Persistence` | Infrastructure는 AppData 계층 책임 |
| `FeatureHome`, `FeatureSearch` 등 | Feature 간 직접 의존 금지 |
| App Target의 `DIContainer`, `AccountNavigator` | Feature는 Coordinator Protocol만 알아야 함 |

---

**테스트**

모듈은 TestDouble 기반 6개 테스트를 포함합니다.

**테스트 대상:** `LoginViewModel`의 viewState 전환과 Intent 흐름

| 테스트 메서드 | 검증 내용 |
|---|---|
| `test_initialState_disablesLoginButton` | 초기 상태에서 로그인 버튼 비활성화 확인 |
| `test_emailAndPasswordChanged_updatesInputAndEnablesLoginButton` | 이메일·비밀번호 입력 시 viewState 갱신과 버튼 활성화 |
| `test_loginButtonTapped_withValidInput_callsUseCaseAndCoordinator` | UseCase·Coordinator 호출 횟수, 인자, 로딩 상태 정상 복원 |
| `test_loginButtonTapped_whenUseCaseThrows_setsErrorMessageAndDoesNotCallCoordinator` | UseCase 실패 시 errorMessage 갱신, Coordinator 미호출 |
| `test_loginButtonTapped_whileLoading_doesNotStartDuplicateRequest` | 로딩 중 중복 요청 차단 (UseCase 1회만 호출) |
| `test_inputChanged_clearsErrorMessage` | 입력 변경 시 errorMessage nil 초기화 |

**TestDouble 구조:**

```text
TestDoubles/
├─ Fixtures/
│  └─ AuthSessionEntity+Fixture.swift    (AuthSessionEntity, AuthTokenEntity, AuthenticatedUserEntity 기본값)
├─ Spies/
│  └─ SpyLoginCoordinator.swift          (loginSucceededCallCount, receivedSession 기록)
└─ Stubs/
   └─ StubLoginUseCase.swift             (stubbedResult, stubbedDelayNanoseconds, executeCallCount, 인자 기록)
```

**비동기 테스트 패턴:**

```swift
// ViewModel Intent는 Task를 반환하고 테스트에서 await으로 완료를 보장합니다.
let task = sut.loginButtonTapped()
await task?.value

XCTAssertEqual(coordinator.loginSucceededCallCount, 1)
XCTAssertFalse(sut.viewState.isLoading)
```

**에러 케이스 패턴:**

```swift
loginUseCase.stubbedResult = .failure(AuthDomainError.invalidCredentials)
let task = sut.loginButtonTapped()
await task?.value

XCTAssertEqual(sut.viewState.errorMessage, AuthDomainError.invalidCredentials.errorDescription)
XCTAssertEqual(coordinator.loginSucceededCallCount, 0)
```

---

**권장 사용 전략**
- App Target의 `RouteBuilder`는 `LoginFactory`와 `DIContainer`를 조합해 `LoginView`를 생성합니다.
- App Target의 `Navigator`는 `LoginCoordinatorProtocol`을 구현해 로그인 성공 후 흐름을 처리합니다.
- ViewModel, ViewState는 Feature 외부에서 직접 생성하지 않습니다. `LoginFactory`를 통해 조립합니다.
- UseCase 구현체는 AppData에 두고 App Target의 `DIContainer`에서 조립합니다. FeatureLogin에 직접 넣지 않습니다.
- Preview와 테스트 환경에서는 `StubLoginUseCase`와 `SpyLoginCoordinator`를 주입합니다.

---

**권장 확장 방식**
1. 소셜 로그인(Apple, Google 등) 추가 → `Scenes/` 하위 별도 Scene 또는 `LoginViewState`에 소셜 로그인 Intent 추가
2. 비밀번호 재설정 링크 → `LoginCoordinatorProtocol`에 `showPasswordReset()` 메서드 추가
3. 회원가입 진입 → `LoginCoordinatorProtocol`에 `showSignUp()` 메서드 추가
4. 이메일 형식 유효성 검증 강화 → `LoginViewState.isLoginButtonEnabled` 또는 UseCase 레이어에서 처리
5. 키보드 자동완성 정책 변경 → `LoginView`의 `textContentType`, `autocorrectionDisabled` 수정
6. 신규 UI 상태(서버 점검 등) → `LoginViewState`에 프로퍼티 추가, ViewModel errorMessage 분기 확장

---

Created by: JEONG, Chi-hong  
Updated: May 2026
