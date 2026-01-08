import WidgetKit
import SwiftUI
import AppIntents

/// Widget Timeline Entry
struct BalanceEntry: TimelineEntry {
    let date: Date
    let balance: AccountBalance?
    let isLoggedIn: Bool
    let errorMessage: String?
    let displayType: BalanceDisplayType
    let cacheToken: String

    static let placeholder = BalanceEntry(
        date: Date(),
        balance: AccountBalance(
            subscriptionBalance: SubscriptionBalance(
                planName: "PRO",
                usedAmount: 65,
                totalAmount: 100,
                unit: "天",
                resetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())
            ),
            payAsYouGoBalance: PayAsYouGoBalance(
                currentBalance: 305.00,
                currency: "CNY",
                monthlySpent: 15.00
            ),
            lastUpdated: Date(),
            userIdentifier: "user@example.com"
        ),
        isLoggedIn: true,
        errorMessage: nil,
        displayType: .payAsYouGo,
        cacheToken: UUID().uuidString
    )

    static let notLoggedIn = BalanceEntry(
        date: Date(),
        balance: nil,
        isLoggedIn: false,
        errorMessage: nil,
        displayType: .payAsYouGo,
        cacheToken: UUID().uuidString
    )
}

/// Timeline Provider for Small Widget (with configuration)
struct BalanceTimelineProvider: AppIntentTimelineProvider {
    private let storage = SharedStorageService.shared

    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func snapshot(for configuration: BalanceWidgetConfigurationIntent, in context: Context) async -> BalanceEntry {
        if context.isPreview {
            return .placeholder
        }
        return loadCurrentEntry(displayType: configuration.displayType)
    }

    func timeline(for configuration: BalanceWidgetConfigurationIntent, in context: Context) async -> Timeline<BalanceEntry> {
        let currentEntry = loadCurrentEntry(displayType: configuration.displayType)

        // 根据设置的刷新间隔计算下次刷新时间
        let refreshInterval = storage.refreshIntervalMinutes
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: refreshInterval,
            to: Date()
        ) ?? Date().addingTimeInterval(Double(refreshInterval) * 60)

        return Timeline(
            entries: [currentEntry],
            policy: .after(nextUpdate)
        )
    }

    private func loadCurrentEntry(displayType: BalanceDisplayType) -> BalanceEntry {
        let isLoggedIn = storage.getLoginState()
        let cacheToken = storage.getWidgetCacheToken()

        guard isLoggedIn else {
            return BalanceEntry(
                date: Date(),
                balance: nil,
                isLoggedIn: false,
                errorMessage: nil,
                displayType: displayType,
                cacheToken: cacheToken
            )
        }

        if let balance = storage.getBalanceData() {
            return BalanceEntry(
                date: Date(),
                balance: balance,
                isLoggedIn: true,
                errorMessage: nil,
                displayType: displayType,
                cacheToken: cacheToken
            )
        }

        return BalanceEntry(
            date: Date(),
            balance: nil,
            isLoggedIn: true,
            errorMessage: "暂无数据",
            displayType: displayType,
            cacheToken: cacheToken
        )
    }
}

/// Timeline Provider for Medium/Large Widget (static, no configuration)
struct StaticBalanceTimelineProvider: TimelineProvider {
    private let storage = SharedStorageService.shared

    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let currentEntry = loadCurrentEntry()

        let refreshInterval = storage.refreshIntervalMinutes
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: refreshInterval,
            to: Date()
        ) ?? Date().addingTimeInterval(Double(refreshInterval) * 60)

        let timeline = Timeline(
            entries: [currentEntry],
            policy: .after(nextUpdate)
        )
        completion(timeline)
    }

    private func loadCurrentEntry() -> BalanceEntry {
        let isLoggedIn = storage.getLoginState()
        let cacheToken = storage.getWidgetCacheToken()

        guard isLoggedIn else {
            return BalanceEntry(
                date: Date(),
                balance: nil,
                isLoggedIn: false,
                errorMessage: nil,
                displayType: .payAsYouGo,
                cacheToken: cacheToken
            )
        }

        if let balance = storage.getBalanceData() {
            return BalanceEntry(
                date: Date(),
                balance: balance,
                isLoggedIn: true,
                errorMessage: nil,
                displayType: .payAsYouGo,
                cacheToken: cacheToken
            )
        }

        return BalanceEntry(
            date: Date(),
            balance: nil,
            isLoggedIn: true,
            errorMessage: "暂无数据",
            displayType: .payAsYouGo,
            cacheToken: cacheToken
        )
    }
}
