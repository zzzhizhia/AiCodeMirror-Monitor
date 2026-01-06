import Foundation

/// App Group 共享存储服务
/// 用于在主 App 和 Widget 之间共享非敏感数据
public final class SharedStorageService {
    public static let shared = SharedStorageService()

    private let appGroupIdentifier = "group.com.aicodemirror-monitor"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Balance Data

    private let balanceDataKey = "cached_balance_data"

    /// 保存余额数据 (供 Widget 读取)
    public func saveBalanceData(_ balance: AccountBalance) throws {
        guard let defaults = sharedDefaults else {
            throw StorageError.noContainer
        }

        let data = try JSONEncoder().encode(balance)
        defaults.set(data, forKey: balanceDataKey)
        defaults.synchronize()
    }

    /// 读取余额数据
    public func getBalanceData() -> AccountBalance? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: balanceDataKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(AccountBalance.self, from: data)
    }

    // MARK: - Widget Entry

    private let widgetEntryKey = "widget_entry_data"

    public func saveWidgetEntry(_ entry: WidgetBalanceEntry) throws {
        guard let defaults = sharedDefaults else {
            throw StorageError.noContainer
        }

        let data = try JSONEncoder().encode(entry)
        defaults.set(data, forKey: widgetEntryKey)
        defaults.synchronize()
    }

    public func getWidgetEntry() -> WidgetBalanceEntry? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: widgetEntryKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetBalanceEntry.self, from: data)
    }

    // MARK: - Login State

    private let isLoggedInKey = "is_logged_in"

    public func saveLoginState(_ isLoggedIn: Bool) {
        sharedDefaults?.set(isLoggedIn, forKey: isLoggedInKey)
        sharedDefaults?.synchronize()
    }

    public func getLoginState() -> Bool {
        return sharedDefaults?.bool(forKey: isLoggedInKey) ?? false
    }

    // MARK: - Last Update Time

    private let lastUpdateKey = "last_update_time"

    public func saveLastUpdateTime(_ date: Date) {
        sharedDefaults?.set(date, forKey: lastUpdateKey)
        sharedDefaults?.synchronize()
    }

    public func getLastUpdateTime() -> Date? {
        return sharedDefaults?.object(forKey: lastUpdateKey) as? Date
    }

    // MARK: - App Settings

    private let settingsKey = "app_settings"

    public func saveSettings(_ settings: AppSettings) throws {
        guard let defaults = sharedDefaults else {
            throw StorageError.noContainer
        }

        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: settingsKey)
        defaults.synchronize()
    }

    public func getSettings() -> AppSettings {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    // MARK: - Refresh Interval

    public var refreshIntervalMinutes: Int {
        get { getSettings().refreshIntervalMinutes }
        set {
            var settings = getSettings()
            settings.refreshIntervalMinutes = newValue
            try? saveSettings(settings)
        }
    }

    // MARK: - Low Balance Threshold

    public var lowBalanceThreshold: Double {
        get { getSettings().lowBalanceThreshold }
        set {
            var settings = getSettings()
            settings.lowBalanceThreshold = newValue
            try? saveSettings(settings)
        }
    }

    // MARK: - Notifications Enabled

    public var notificationsEnabled: Bool {
        get { getSettings().notificationsEnabled }
        set {
            var settings = getSettings()
            settings.notificationsEnabled = newValue
            try? saveSettings(settings)
        }
    }

    // MARK: - Last Notification Date

    private let lastNotificationKey = "last_notification_date"

    public func saveLastNotificationDate(_ date: Date) {
        sharedDefaults?.set(date, forKey: lastNotificationKey)
        sharedDefaults?.synchronize()
    }

    public func getLastNotificationDate() -> Date? {
        return sharedDefaults?.object(forKey: lastNotificationKey) as? Date
    }

    // MARK: - Clear All

    public func clearAll() {
        guard let defaults = sharedDefaults else { return }

        let keys = [
            balanceDataKey,
            widgetEntryKey,
            isLoggedInKey,
            lastUpdateKey,
            settingsKey,
            lastNotificationKey
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
    }
}

// MARK: - Errors

public enum StorageError: Error, LocalizedError {
    case noContainer
    case saveFailed
    case readFailed

    public var errorDescription: String? {
        switch self {
        case .noContainer:
            return "无法访问 App Group 容器"
        case .saveFailed:
            return "数据保存失败"
        case .readFailed:
            return "数据读取失败"
        }
    }
}
