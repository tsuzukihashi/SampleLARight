import LocalAuthentication
import Foundation

// NOTE: 本来ならProtocolを作ってDIできるようにする
class AppAuthManager: ObservableObject {
    static let shared: AppAuthManager = .init(
        loginRight: .init(requirement: .biometry(fallback: .devicePasscode)),
        rightStore: .shared
    )

    private let loginRight: LARight
    private let rightStore: LARightStore
    private let dataIdentifier: String = "secretText"

    private init(loginRight: LARight, rightStore: LARightStore) {
        self.loginRight = loginRight
        self.rightStore = rightStore
    }

    @Published var currentState: LARight.State = .notAuthorized
    @Published var secretValue: String = ""

    @MainActor
    func login() async throws {
        try await loginRight.authorize(
            localizedReason: "セキュアなデータにアクセスするために利用します"
        )
        currentState = loginRight.state
    }

    @MainActor
    func logout() async {
        await loginRight.deauthorize()
        currentState = loginRight.state
    }

    func store(data: Data) async throws {
        let right = LARight(requirement: .biometry(fallback: .devicePasscode))
        try await right.authorize(
            localizedReason: "セキュアにデータを保存するために利用します"
        )
        _ = try await LARightStore.shared.saveRight(
            right,
            identifier: dataIdentifier,
            secret: data
        )
    }

    func fetchData() async throws -> Data {
        let right = try await LARightStore.shared.right(forIdentifier: dataIdentifier)
        try await right.authorize(
            localizedReason: "セキュアなデータにアクセスするために利用します"
        )
        return try await right.secret.rawData
    }

    func removeData() async throws {
        try await LARightStore.shared.removeRight(forIdentifier: dataIdentifier)
    }
}
