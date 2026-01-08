import Foundation

// MARK: - 数据获取方式

/// 数据获取方式
public enum FetchMethod: String, Codable {
    case lightweight = "lightweight"  // 轻量级 HTTP 直接解析
    case webview = "webview"          // WebView 渲染
}

// MARK: - 账户余额数据模型

/// 账户余额数据 - 主 App 和 Widget 共享
public struct AccountBalance: Codable, Equatable {
    /// 订阅余额
    public let subscriptionBalance: SubscriptionBalance?
    /// 按量付费余额 (PAYGO)
    public let payAsYouGoBalance: PayAsYouGoBalance?
    /// 数据最后更新时间
    public let lastUpdated: Date
    /// 用户标识 (邮箱/手机号)
    public let userIdentifier: String?
    /// 数据获取方式
    public let fetchMethod: FetchMethod?

    public init(
        subscriptionBalance: SubscriptionBalance? = nil,
        payAsYouGoBalance: PayAsYouGoBalance? = nil,
        lastUpdated: Date = Date(),
        userIdentifier: String? = nil,
        fetchMethod: FetchMethod? = nil
    ) {
        self.subscriptionBalance = subscriptionBalance
        self.payAsYouGoBalance = payAsYouGoBalance
        self.lastUpdated = lastUpdated
        self.userIdentifier = userIdentifier
        self.fetchMethod = fetchMethod
    }
}

/// 订阅余额
public struct SubscriptionBalance: Codable, Equatable {
    /// 套餐名称 (PRO, MAX, ULTRA 等)
    public let planName: String
    /// 已使用额度
    public let usedAmount: Double
    /// 总额度
    public let totalAmount: Double
    /// 额度单位
    public let unit: String
    /// 重置日期 (订阅周期结束日期)
    public let resetDate: Date?

    public init(
        planName: String,
        usedAmount: Double,
        totalAmount: Double,
        unit: String,
        resetDate: Date? = nil
    ) {
        self.planName = planName
        self.usedAmount = usedAmount
        self.totalAmount = totalAmount
        self.unit = unit
        self.resetDate = resetDate
    }

    /// 剩余额度
    public var remainingAmount: Double {
        max(0, totalAmount - usedAmount)
    }

    /// 使用百分比
    public var usagePercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return min(1.0, usedAmount / totalAmount)
    }
}

/// 按量付费余额
public struct PayAsYouGoBalance: Codable, Equatable {
    /// 当前余额
    public let currentBalance: Double
    /// 货币单位 (USD, CNY 等)
    public let currency: String
    /// 本月已消费
    public let monthlySpent: Double?

    public init(
        currentBalance: Double,
        currency: String,
        monthlySpent: Double? = nil
    ) {
        self.currentBalance = currentBalance
        self.currency = currency
        self.monthlySpent = monthlySpent
    }

    /// 格式化余额显示
    public var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency == "CNY" ? "¥" : nil
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: currentBalance)) ?? "\(currency) \(currentBalance)"
    }
}

// MARK: - 用户会话

/// 用户会话信息
public struct UserSession: Codable, Equatable {
    /// 会话 Cookie 或 Token
    public let sessionToken: String
    /// 过期时间
    public let expiresAt: Date?
    /// 用户 ID
    public let userId: String?
    /// 用户邮箱/手机号
    public let userIdentifier: String?
    /// 创建时间
    public let createdAt: Date

    public init(
        sessionToken: String,
        expiresAt: Date? = nil,
        userId: String? = nil,
        userIdentifier: String? = nil,
        createdAt: Date = Date()
    ) {
        self.sessionToken = sessionToken
        self.expiresAt = expiresAt
        self.userId = userId
        self.userIdentifier = userIdentifier
        self.createdAt = createdAt
    }

    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Widget Entry

/// Widget 显示数据
public struct WidgetBalanceEntry: Codable {
    public let date: Date
    public let balance: AccountBalance?
    public let isLoggedIn: Bool
    public let errorMessage: String?

    public init(
        date: Date = Date(),
        balance: AccountBalance? = nil,
        isLoggedIn: Bool = false,
        errorMessage: String? = nil
    ) {
        self.date = date
        self.balance = balance
        self.isLoggedIn = isLoggedIn
        self.errorMessage = errorMessage
    }

    public static let placeholder = WidgetBalanceEntry(
        date: Date(),
        balance: AccountBalance(
            subscriptionBalance: SubscriptionBalance(
                planName: "PRO",
                usedAmount: 50,
                totalAmount: 100,
                unit: "天",
                resetDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
            ),
            payAsYouGoBalance: PayAsYouGoBalance(
                currentBalance: 305.00,
                currency: "CNY",
                monthlySpent: 10.00
            ),
            lastUpdated: Date(),
            userIdentifier: "user@example.com"
        ),
        isLoggedIn: true,
        errorMessage: nil
    )

    public static let notLoggedIn = WidgetBalanceEntry(
        date: Date(),
        balance: nil,
        isLoggedIn: false,
        errorMessage: "请先登录"
    )
}

// MARK: - 登录状态

/// 登录状态枚举
public enum AuthState: Equatable {
    case unknown
    case loggedOut
    case loggingIn
    case loggedIn(UserSession)
    case error(String)

    public var isLoggedIn: Bool {
        if case .loggedIn = self { return true }
        return false
    }

    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.loggedOut, .loggedOut),
             (.loggingIn, .loggingIn):
            return true
        case let (.loggedIn(s1), .loggedIn(s2)):
            return s1 == s2
        case let (.error(e1), .error(e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

// MARK: - 设置

/// 应用设置
public struct AppSettings: Codable {
    /// 刷新间隔 (分钟)
    public var refreshIntervalMinutes: Int
    /// 余额预警阈值
    public var lowBalanceThreshold: Double
    /// 是否启用通知
    public var notificationsEnabled: Bool
    /// 上次通知时间 (用于避免重复通知)
    public var lastNotificationDate: Date?

    public init(
        refreshIntervalMinutes: Int = 1,
        lowBalanceThreshold: Double = 10.0,
        notificationsEnabled: Bool = true,
        lastNotificationDate: Date? = nil
    ) {
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.lowBalanceThreshold = lowBalanceThreshold
        self.notificationsEnabled = notificationsEnabled
        self.lastNotificationDate = lastNotificationDate
    }

    public static let `default` = AppSettings()
}
