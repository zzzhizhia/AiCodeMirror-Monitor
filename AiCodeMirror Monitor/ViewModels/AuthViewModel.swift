import Foundation
import Combine

/// 认证视图模型
@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var authState: AuthState = .unknown
    @Published var authError: Error?

    private let keychain = KeychainService.shared
    private let storage = SharedStorageService.shared

    init() {
        checkLoginState()
    }

    /// 检查登录状态
    func checkLoginState() {
        if let session = keychain.getUserSession() {
            if !session.isExpired {
                authState = .loggedIn(session)
                storage.saveLoginState(true)
                return
            } else {
                // Session 已过期，清除
                keychain.clearAll()
            }
        }

        authState = .loggedOut
        storage.saveLoginState(false)
    }

    /// 处理登录成功
    func handleLoginSuccess(cookies: [HTTPCookie]) {
        do {
            try keychain.saveCookies(cookies)

            // 查找 session cookie
            let sessionCookie = cookies.first { cookie in
                let name = cookie.name.lowercased()
                return name.contains("session") ||
                       name.contains("token") ||
                       name.contains("auth") ||
                       name.contains("jwt") ||
                       name.contains("sid")
            }

            let session = UserSession(
                sessionToken: sessionCookie?.value ?? cookies.first?.value ?? "",
                expiresAt: sessionCookie?.expiresDate,
                userId: nil,
                userIdentifier: nil,
                createdAt: Date()
            )

            try keychain.saveUserSession(session)

            authState = .loggedIn(session)
            storage.saveLoginState(true)

            // 刷新 Widget
            storage.bumpWidgetCacheToken()
            storage.reloadWidgets()

        } catch {
            authError = error
            authState = .error(error.localizedDescription)
        }
    }

    /// 处理登录失败
    func handleLoginFailure(error: Error) {
        authError = error
        authState = .error(error.localizedDescription)
    }

    /// 登出
    func logout() {
        keychain.clearAll()
        storage.clearAll()

        authState = .loggedOut

        // 刷新 Widget
        storage.bumpWidgetCacheToken()
        storage.reloadWidgets()
    }

    /// 是否已登录
    var isLoggedIn: Bool {
        authState.isLoggedIn
    }
}
