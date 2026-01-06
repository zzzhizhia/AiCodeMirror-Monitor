import Foundation
import Security

/// Keychain 服务 - 用于安全存储敏感信息
public final class KeychainService {
    public static let shared = KeychainService()

    private let serviceName = "com.aicodemirror-monitor"
    private let accessGroup = "group.com.aicodemirror-monitor"

    private init() {}

    // MARK: - Session Token

    private let sessionTokenKey = "session_token"

    public func saveSessionToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data: data, forKey: sessionTokenKey)
    }

    public func getSessionToken() -> String? {
        guard let data = try? getData(forKey: sessionTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteSessionToken() throws {
        try delete(forKey: sessionTokenKey)
    }

    // MARK: - Cookies

    private let cookiesKey = "auth_cookies"

    public func saveCookies(_ cookies: [HTTPCookie]) throws {
        // 将 Cookie properties 转换为可 JSON 序列化的格式
        let cookieData: [[String: Any]] = cookies.compactMap { cookie -> [String: Any]? in
            guard let properties = cookie.properties else { return nil }

            var serializable: [String: Any] = [:]
            for (key, value) in properties {
                let keyString = key.rawValue
                if let date = value as? Date {
                    // 将 Date 转换为时间戳
                    serializable[keyString] = date.timeIntervalSince1970
                    serializable[keyString + "_isDate"] = true
                } else if let stringValue = value as? String {
                    serializable[keyString] = stringValue
                } else if let numberValue = value as? NSNumber {
                    serializable[keyString] = numberValue
                } else if let boolValue = value as? Bool {
                    serializable[keyString] = boolValue
                }
            }
            return serializable
        }

        let data = try JSONSerialization.data(withJSONObject: cookieData)
        try save(data: data, forKey: cookiesKey)
    }

    public func getCookies() -> [HTTPCookie] {
        guard let data = try? getData(forKey: cookiesKey),
              let cookieArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }

        return cookieArray.compactMap { dict -> HTTPCookie? in
            var properties: [HTTPCookiePropertyKey: Any] = [:]

            for (key, value) in dict {
                // 跳过标记键
                if key.hasSuffix("_isDate") { continue }

                let cookieKey = HTTPCookiePropertyKey(key)

                // 检查是否是日期字段
                if dict[key + "_isDate"] as? Bool == true, let timestamp = value as? TimeInterval {
                    properties[cookieKey] = Date(timeIntervalSince1970: timestamp)
                } else {
                    properties[cookieKey] = value
                }
            }

            return HTTPCookie(properties: properties)
        }
    }

    public func deleteCookies() throws {
        try delete(forKey: cookiesKey)
    }

    // MARK: - User Session

    private let userSessionKey = "user_session"

    public func saveUserSession(_ session: UserSession) throws {
        let data = try JSONEncoder().encode(session)
        try save(data: data, forKey: userSessionKey)
    }

    public func getUserSession() -> UserSession? {
        guard let data = try? getData(forKey: userSessionKey) else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    public func deleteUserSession() throws {
        try delete(forKey: userSessionKey)
    }

    // MARK: - Clear All

    public func clearAll() {
        try? deleteSessionToken()
        try? deleteCookies()
        try? deleteUserSession()
    }

    // MARK: - Private Methods

    private func save(data: Data, forKey key: String) throws {
        // 先删除已存在的项
        try? delete(forKey: key)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // 生产环境添加 access group
        #if !DEBUG
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func getData(forKey key: String) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        #if !DEBUG
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.readFailed(status)
        }
    }

    private func delete(forKey key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        #if !DEBUG
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Errors

public enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain 保存失败: \(status)"
        case .readFailed(let status):
            return "Keychain 读取失败: \(status)"
        case .deleteFailed(let status):
            return "Keychain 删除失败: \(status)"
        case .encodingFailed:
            return "数据编码失败"
        }
    }
}
