import WidgetKit
import SwiftUI

/// 小尺寸余额 Widget（可配置显示类型）
struct SmallBalanceWidget: Widget {
    let kind: String = SharedStorageService.WidgetKind.smallBalance

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BalanceWidgetConfigurationIntent.self,
            provider: BalanceTimelineProvider()
        ) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("余额")
        .description("显示您的 AICodeMirror 余额")
        .supportedFamilies([.systemSmall])
    }
}

/// 中大尺寸余额 Widget（显示全部信息）
struct BalanceWidget: Widget {
    let kind: String = SharedStorageService.WidgetKind.balanceDetail

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: StaticBalanceTimelineProvider()
        ) { entry in
            BalanceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AICodeMirror 余额详情")
        .description("显示您的 AICodeMirror 账户完整余额信息")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

/// Widget 入口视图（用于 Medium/Large）
struct BalanceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BalanceEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .id(entry.cacheToken)
    }
}

// MARK: - Previews

#Preview("Small - PayGo", as: .systemSmall) {
    SmallBalanceWidget()
} timeline: {
    BalanceEntry.placeholder
    BalanceEntry.notLoggedIn
}

#Preview("Small - Subscription", as: .systemSmall) {
    SmallBalanceWidget()
} timeline: {
    BalanceEntry(
        date: Date(),
        balance: AccountBalance(
            subscriptionBalance: SubscriptionBalance(
                planName: "PRO",
                usedAmount: 65,
                totalAmount: 100,
                unit: "天",
                resetDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())
            ),
            payAsYouGoBalance: nil,
            lastUpdated: Date(),
            userIdentifier: "user@example.com"
        ),
        isLoggedIn: true,
        errorMessage: nil,
        displayType: .subscription,
        cacheToken: UUID().uuidString
    )
}

#Preview("Medium", as: .systemMedium) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
}
