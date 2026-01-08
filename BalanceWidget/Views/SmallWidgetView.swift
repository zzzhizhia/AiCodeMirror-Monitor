import SwiftUI
import WidgetKit

/// 小尺寸 Widget 视图 - macOS 原生风格
struct SmallWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        Group {
            if !entry.isLoggedIn {
                notLoggedInView
            } else if let balance = entry.balance {
                loggedInView(balance: balance)
            } else {
                errorView
            }
        }
        .id(entry.cacheToken)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var notLoggedInView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text("请先登录")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func loggedInView(balance: AccountBalance) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 根据 displayType 显示对应内容
            switch entry.displayType {
            case .payAsYouGo:
                payAsYouGoView(balance: balance)
            case .subscription:
                subscriptionView(balance: balance)
            }

            // WebView 标识
            if balance.fetchMethod == .webview {
                HStack {
                    Spacer()
                    Text("🐢")
                        .font(.caption2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    @ViewBuilder
    private func payAsYouGoView(balance: AccountBalance) -> some View {
        // 标题
        HStack(spacing: 4) {
            Image(systemName: "creditcard.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("按量付费余额")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }

        Spacer()

        // 余额显示
        if let paygo = balance.payAsYouGoBalance {
            Text(paygo.formattedBalance)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
        } else {
            Text("暂无数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Spacer()
    }

    @ViewBuilder
    private func subscriptionView(balance: AccountBalance) -> some View {
        // 标题
        if let sub = balance.subscriptionBalance {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("订阅余额")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "¥%.2f", sub.remainingAmount))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)

            Spacer()
        } else {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("订阅余额")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("暂无数据")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundStyle(.orange)

            Text(entry.errorMessage ?? "加载失败")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
