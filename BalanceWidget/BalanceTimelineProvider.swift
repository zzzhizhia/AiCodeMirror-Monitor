import WidgetKit
import SwiftUI

/// Widget Timeline Entry
struct BalanceEntry: TimelineEntry {
    let date: Date
    let balance: AccountBalance?
    let isLoggedIn: Bool
    let errorMessage: String?

    static let placeholder = BalanceEntry(
        date: Date(),
        balance: AccountBalance(
            subscriptionBalance: SubscriptionBalance(
                planName: "PRO",
                usedAmount: 65,
                totalAmount: 100,
                unit: "USD",
                resetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())
            ),
            payAsYouGoBalance: PayAsYouGoBalance(
                currentBalance: 42.50,
                currency: "USD",
                monthlySpent: 15.00
            ),
            lastUpdated: Date(),
            userIdentifier: "user@example.com"
        ),
        isLoggedIn: true,
        errorMessage: nil
    )

    static let notLoggedIn = BalanceEntry(
        date: Date(),
        balance: nil,
        isLoggedIn: false,
        errorMessage: nil
    )
}

/// Timeline Provider
struct BalanceTimelineProvider: TimelineProvider {
    private let storage = SharedStorageService.shared

    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        let entry = loadCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let currentEntry = loadCurrentEntry()

        // 根据设置的刷新间隔计算下次刷新时间
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

        guard isLoggedIn else {
            return .notLoggedIn
        }

        if let balance = storage.getBalanceData() {
            return BalanceEntry(
                date: Date(),
                balance: balance,
                isLoggedIn: true,
                errorMessage: nil
            )
        }

        return BalanceEntry(
            date: Date(),
            balance: nil,
            isLoggedIn: true,
            errorMessage: "暂无数据"
        )
    }
}
