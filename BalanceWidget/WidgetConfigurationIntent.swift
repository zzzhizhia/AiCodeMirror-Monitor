import AppIntents
import WidgetKit

/// 余额显示类型
enum BalanceDisplayType: String, AppEnum {
    case payAsYouGo = "paygo"
    case subscription = "subscription"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "余额类型"

    static var caseDisplayRepresentations: [BalanceDisplayType: DisplayRepresentation] = [
        .payAsYouGo: DisplayRepresentation(title: "按量付费余额"),
        .subscription: DisplayRepresentation(title: "订阅余额")
    ]
}

/// Small Widget 配置 Intent
struct BalanceWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择显示类型"
    static var description = IntentDescription("选择要显示的余额类型")

    @Parameter(title: "余额类型", default: .payAsYouGo)
    var displayType: BalanceDisplayType
}
