import Foundation

/// 认证服务 - 处理 API 登录
final class AuthService {
    static let shared = AuthService()

    private let baseURL = "https://www.aicodemirror.com"
    private let session: URLSession
    private let cookieStorage: HTTPCookieStorage

    private init() {
        // 使用自定义的 cookie storage
        cookieStorage = HTTPCookieStorage.shared

        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookieStorage
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true

        session = URLSession(configuration: config)
    }

    /// 登录
    func login(identifier: String, password: String) async throws -> [HTTPCookie] {
        // 清除旧的 cookies
        if let url = URL(string: baseURL),
           let cookies = cookieStorage.cookies(for: url) {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }

        // 1. 获取 CSRF token
        let csrfToken = try await fetchCSRFToken()

        // 2. 提交登录
        try await submitLogin(
            identifier: identifier,
            password: password,
            csrfToken: csrfToken
        )

        // 3. 验证登录并获取 cookies
        return try await verifyLoginAndGetCookies()
    }

    // MARK: - Private

    /// 获取 CSRF token
    private func fetchCSRFToken() async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/auth/csrf") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("\(baseURL)/login", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.csrfFetchFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let csrfToken = json["csrfToken"] as? String else {
            throw AuthError.csrfParseFailed
        }

        return csrfToken
    }

    /// 提交登录请求
    private func submitLogin(identifier: String, password: String, csrfToken: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/auth/callback/credentials") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("1", forHTTPHeaderField: "X-Auth-Return-Redirect")
        request.setValue("\(baseURL)/login", forHTTPHeaderField: "Referer")
        request.setValue(baseURL, forHTTPHeaderField: "Origin")

        // 构建表单数据
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "identifier", value: identifier),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "csrfToken", value: csrfToken),
            URLQueryItem(name: "callbackUrl", value: "\(baseURL)/login")
        ]

        request.httpBody = components.query?.data(using: .utf8)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.loginFailed
        }

        // NextAuth 成功返回 200 或 302
        guard (200...399).contains(httpResponse.statusCode) else {
            throw AuthError.loginFailed
        }
    }

    /// 验证登录状态并获取 cookies
    private func verifyLoginAndGetCookies() async throws -> [HTTPCookie] {
        guard let url = URL(string: "\(baseURL)/api/auth/session") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("\(baseURL)/login", forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.loginFailed
        }

        // 检查 session 响应是否包含用户信息
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["user"] != nil else {
            throw AuthError.invalidCredentials
        }

        // 收集所有相关 cookies
        guard let baseURLObj = URL(string: baseURL) else {
            throw AuthError.invalidURL
        }

        let cookies = cookieStorage.cookies(for: baseURLObj) ?? []

        // 确保有 session cookie
        let hasSessionCookie = cookies.contains { cookie in
            cookie.name.contains("session") || cookie.name.contains("authjs")
        }

        guard hasSessionCookie else {
            throw AuthError.loginFailed
        }

        return cookies
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case invalidURL
    case csrfFetchFailed
    case csrfParseFailed
    case loginFailed
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .csrfFetchFailed:
            return "获取 CSRF token 失败"
        case .csrfParseFailed:
            return "解析 CSRF token 失败"
        case .loginFailed:
            return "登录失败"
        case .invalidCredentials:
            return "账号或密码错误"
        }
    }
}
