import WidgetKit
import SwiftUI

/// 余额 Widget
struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: BalanceTimelineProvider()
        ) { entry in
            BalanceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AICodeMirror 余额")
        .description("显示您的 AICodeMirror 账户余额")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Widget 入口视图
struct BalanceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BalanceTimelineProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    BalanceWidget()
} timeline: {
    BalanceEntry.placeholder
    BalanceEntry.notLoggedIn
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
