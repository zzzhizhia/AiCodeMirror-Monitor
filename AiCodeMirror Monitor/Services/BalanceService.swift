import Foundation

/// 余额获取服务
final class BalanceService {
    private let keychain = KeychainService.shared

    init() {}

    /// 获取账户余额
    func fetchBalance() async throws -> AccountBalance {
        let cookies = keychain.getCookies()
        guard !cookies.isEmpty else {
            throw BalanceError.notLoggedIn
        }

        return try await fetchBalanceViaAPI(cookies: cookies)
    }

    // MARK: - API 请求

    /// 通过 API 获取余额
    private func fetchBalanceViaAPI(cookies: [HTTPCookie]) async throws -> AccountBalance {
        guard let url = URL(string: "https://aicodemirror.com/api/wallet") else {
            throw BalanceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 设置 cookies
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BalanceError.requestFailed
        }

        guard httpResponse.statusCode == 200 else {
            throw BalanceError.requestFailed
        }

        return try parseAPIResponse(data)
    }

    /// 解析 API 响应
    /// 格式: {"success": true, "data": {"balance": "197713", "bonusBalance": "1851"}}
    private func parseAPIResponse(_ data: Data) throws -> AccountBalance {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let dataObj = json["data"] as? [String: Any] else {
            throw BalanceError.parseError
        }

        var subscriptionBalance: SubscriptionBalance?
        var payAsYouGoBalance: PayAsYouGoBalance?

        // 解析 balance（订阅余额，单位：厘）
        if let balanceStr = dataObj["balance"] as? String,
           let balanceValue = Int(balanceStr) {
            let amount = Double(balanceValue) / 1000.0  // 厘转元

            subscriptionBalance = SubscriptionBalance(
                planName: "PRO",
                usedAmount: 0,
                totalAmount: amount,
                unit: "CNY",
                resetDate: nil
            )
        }

        // 解析 bonusBalance（按量付费余额，单位：厘）
        if let bonusStr = dataObj["bonusBalance"] as? String,
           let bonusValue = Int(bonusStr) {
            let amount = Double(bonusValue) / 1000.0  // 厘转元

            payAsYouGoBalance = PayAsYouGoBalance(
                currentBalance: amount,
                currency: "CNY",
                monthlySpent: nil
            )
        }

        guard subscriptionBalance != nil || payAsYouGoBalance != nil else {
            throw BalanceError.parseError
        }

        return AccountBalance(
            subscriptionBalance: subscriptionBalance,
            payAsYouGoBalance: payAsYouGoBalance,
            lastUpdated: Date(),
            userIdentifier: nil,
            fetchMethod: .lightweight
        )
    }
}

// MARK: - Errors

enum BalanceError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case parseError
    case notLoggedIn

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .requestFailed:
            return "请求失败"
        case .parseError:
            return "数据解析失败"
        case .notLoggedIn:
            return "未登录，请先登录"
        }
    }
}
