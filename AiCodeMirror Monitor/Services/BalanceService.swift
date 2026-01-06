import Foundation
import WebKit

/// 余额获取服务
final class BalanceService {
    private let keychain = KeychainService.shared

    init() {}

    /// 获取账户余额 - 通过爬取 Dashboard 页面
    @MainActor
    func fetchBalance() async throws -> AccountBalance {
        let cookies = keychain.getCookies()
        guard !cookies.isEmpty else {
            throw BalanceError.notLoggedIn
        }

        return try await fetchBalanceViaWebScraping(cookies: cookies)
    }

    /// 通过 WKWebView 爬取 Dashboard 页面获取余额
    @MainActor
    private func fetchBalanceViaWebScraping(cookies: [HTTPCookie]) async throws -> AccountBalance {
        // 使用非持久化数据存储，避免缓存
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()

        // 设置 cookies
        let cookieStore = configuration.websiteDataStore.httpCookieStore
        for cookie in cookies {
            await cookieStore.setCookie(cookie)
        }

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 800), configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        // 直接访问钱包管理页面，余额信息更直接
        guard let url = URL(string: "https://aicodemirror.com/dashboard/wallet") else {
            throw BalanceError.invalidURL
        }

        // 禁用缓存
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        // 加载页面
        webView.load(request)

        // 等待页面加载完成（最多 20 秒）
        try await waitForPageLoad(webView: webView, timeout: 20)

        // 等待页面完全渲染（等待余额出现）
        try await waitForBalanceElement(webView: webView, timeout: 10)

        // 提取数据
        let balance = try await extractBalanceFromPage(webView: webView)

        return balance
    }

    /// 等待余额元素出现
    @MainActor
    private func waitForBalanceElement(webView: WKWebView, timeout: TimeInterval) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            // 检查页面是否包含余额信息
            let checkJS = #"""
            (function() {
                var text = document.body.innerText || '';
                // 检查是否有余额相关内容
                if (text.includes('当前余额') || text.includes('钱包余额') || text.includes('账户余额')) {
                    return 'ready';
                }
                return 'waiting';
            })();
            """#

            if let result = try? await webView.evaluateJavaScript(checkJS) as? String,
               result == "ready" {
                // 找到余额元素，再等待 1 秒让数据加载完成
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return
            }

            try await Task.sleep(nanoseconds: 500_000_000)
        }

        // 超时后继续尝试提取
        print("等待余额元素超时，继续尝试提取")
    }

    @MainActor
    private func waitForPageLoad(webView: WKWebView, timeout: TimeInterval) async throws {
        let startTime = Date()

        while true {
            // 检查是否超时
            if Date().timeIntervalSince(startTime) > timeout {
                throw BalanceError.timeout
            }

            // 检查页面是否加载完成
            let isLoading = webView.isLoading
            if !isLoading {
                return
            }

            // 等待 0.5 秒再检查
            try await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    @MainActor
    private func extractBalanceFromPage(webView: WKWebView) async throws -> AccountBalance {
        let javascript = #"""
        (function() {
            try {
                var result = {
                    subscription: null,
                    paygo: null,
                    email: null,
                    raw: {}
                };

                var bodyText = document.body.innerText || '';
                result.raw.bodyText = bodyText.substring(0, 3000);

                // 方法1: 查找包含 "¥" 或 "￥" 的余额数字
                var allElements = document.querySelectorAll('*');
                for (var i = 0; i < allElements.length; i++) {
                    var el = allElements[i];
                    var text = el.innerText || '';

                    // 查找 ¥ 或 ￥ 后面的数字
                    var yenMatch = text.match(/[¥￥]\s*([\d,.]+)/);
                    if (yenMatch && el.children.length === 0) {
                        var amount = parseFloat(yenMatch[1].replace(/,/g, ''));
                        if (!isNaN(amount) && amount > 0) {
                            result.raw.foundYen = yenMatch[0];
                            result.paygo = {
                                balance: amount,
                                currency: 'CNY'
                            };
                            break;
                        }
                    }
                }

                // 方法2: 查找"当前余额"旁边的数字
                if (!result.paygo) {
                    var balanceMatch = bodyText.match(/当前余额[^\d]*([¥￥]?\s*[\d,.]+)/);
                    if (balanceMatch) {
                        var amount = parseFloat(balanceMatch[1].replace(/[¥￥,\s]/g, ''));
                        if (!isNaN(amount)) {
                            result.raw.foundBalance = balanceMatch[0];
                            result.paygo = {
                                balance: amount,
                                currency: 'CNY'
                            };
                        }
                    }
                }

                // 方法3: 查找"钱包余额"或"账户余额"
                if (!result.paygo) {
                    var walletMatch = bodyText.match(/(钱包余额|账户余额)[^\d]*([¥￥]?\s*[\d,.]+)/);
                    if (walletMatch) {
                        var amount = parseFloat(walletMatch[2].replace(/[¥￥,\s]/g, ''));
                        if (!isNaN(amount)) {
                            result.raw.foundWallet = walletMatch[0];
                            result.paygo = {
                                balance: amount,
                                currency: 'CNY'
                            };
                        }
                    }
                }

                // 方法4: 查找大数字（可能是余额）
                if (!result.paygo) {
                    var bigNumberMatch = bodyText.match(/(\d+\.\d{2})/g);
                    if (bigNumberMatch && bigNumberMatch.length > 0) {
                        result.raw.bigNumbers = bigNumberMatch.slice(0, 5);
                    }
                }

                // 提取订阅信息
                var subMatch = bodyText.match(/(PRO|VIP\d*|PLUS|BASIC)/i);
                if (subMatch) {
                    result.subscription = {
                        plan: subMatch[1].toUpperCase()
                    };
                }

                // 提取剩余天数
                var daysMatch = bodyText.match(/(\d+)\s*剩余天数/);
                if (daysMatch && result.subscription) {
                    result.subscription.daysRemaining = parseInt(daysMatch[1]);
                }

                return JSON.stringify(result);
            } catch(e) {
                return JSON.stringify({ error: e.message });
            }
        })();
        """#

        let result: Any?
        do {
            result = try await webView.evaluateJavaScript(javascript)
        } catch {
            throw BalanceError.javascriptError(error.localizedDescription)
        }

        guard let jsonString = result as? String,
              let data = jsonString.data(using: .utf8) else {
            throw BalanceError.parseError
        }

        return try parseScrapedData(data)
    }

    private func parseScrapedData(_ data: Data) throws -> AccountBalance {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BalanceError.parseError
        }

        if let errorMsg = json["error"] as? String {
            throw BalanceError.javascriptError(errorMsg)
        }

        var subscriptionBalance: SubscriptionBalance?
        var payAsYouGoBalance: PayAsYouGoBalance?
        let userIdentifier = json["email"] as? String

        // 解析按量付费余额
        if let paygo = json["paygo"] as? [String: Any] {
            let balance = (paygo["balance"] as? Double) ?? (paygo["balance"] as? Int).map { Double($0) } ?? 0
            payAsYouGoBalance = PayAsYouGoBalance(
                currentBalance: balance,
                currency: paygo["currency"] as? String ?? "CNY",
                monthlySpent: paygo["monthlySpent"] as? Double
            )
        }

        // 解析订阅信息
        if let sub = json["subscription"] as? [String: Any] {
            let daysRemaining = sub["daysRemaining"] as? Int
            subscriptionBalance = SubscriptionBalance(
                planName: sub["plan"] as? String ?? "Unknown",
                usedAmount: 0,
                totalAmount: Double(daysRemaining ?? 0),
                unit: "天",
                resetDate: nil
            )
        }

        // 从 raw 数据中尝试提取
        if payAsYouGoBalance == nil, let raw = json["raw"] as? [String: Any] {
            // 尝试从 bigNumbers 中获取
            if let bigNumbers = raw["bigNumbers"] as? [String], !bigNumbers.isEmpty {
                if let amount = Double(bigNumbers[0]) {
                    payAsYouGoBalance = PayAsYouGoBalance(
                        currentBalance: amount,
                        currency: "CNY",
                        monthlySpent: nil
                    )
                }
            }

            // 打印原始数据用于调试
            if let bodyText = raw["bodyText"] as? String {
                print("页面文本: \(bodyText.prefix(500))")
            }
            if let foundYen = raw["foundYen"] as? String {
                print("找到余额: \(foundYen)")
            }
            if let foundBalance = raw["foundBalance"] as? String {
                print("找到当前余额: \(foundBalance)")
            }
        }

        return AccountBalance(
            subscriptionBalance: subscriptionBalance,
            payAsYouGoBalance: payAsYouGoBalance,
            lastUpdated: Date(),
            userIdentifier: userIdentifier
        )
    }
}

// MARK: - Errors

enum BalanceError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case parseError
    case apiNotFound
    case notLoggedIn
    case javascriptError(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .requestFailed:
            return "请求失败"
        case .parseError:
            return "数据解析失败"
        case .apiNotFound:
            return "未找到 API 端点"
        case .notLoggedIn:
            return "未登录，请先登录"
        case .javascriptError(let msg):
            return "JavaScript 错误: \(msg)"
        case .timeout:
            return "请求超时"
        }
    }
}
