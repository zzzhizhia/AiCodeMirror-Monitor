import SwiftUI
import WidgetKit

/// 中尺寸 Widget 视图 - macOS 原生风格
struct MediumWidgetView: View {
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
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var notLoggedInView: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("未登录")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("点击打开 App 登录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func loggedInView(balance: AccountBalance) -> some View {
        HStack(spacing: 0) {
            // 左侧 - 按量付费余额
            if let paygo = balance.payAsYouGoBalance {
                VStack(alignment: .leading, spacing: 6) {
                    Label("按量付费", systemImage: "creditcard.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(paygo.formattedBalance)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)

                    if let spent = paygo.monthlySpent {
                        Text("本月: \(String(format: "%.2f", spent))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            if balance.payAsYouGoBalance != nil && balance.subscriptionBalance != nil {
                Divider()
                    .padding(.vertical, 12)
            }

            // 右侧 - 订阅余额
            if let sub = balance.subscriptionBalance {
                VStack(alignment: .leading, spacing: 6) {
                    Label(sub.planName, systemImage: "star.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(sub.remainingAmount))/\(Int(sub.totalAmount))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.primary)

                        ProgressView(value: 1 - sub.usagePercentage)
                            .tint(progressColor(for: sub.usagePercentage))
                    }

                    if let resetDate = sub.resetDate {
                        Text("重置: \(resetDate, style: .date)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }

    private func progressColor(for percentage: Double) -> Color {
        if percentage > 0.8 {
            return .red
        } else if percentage > 0.6 {
            return .orange
        } else {
            return .green
        }
    }

    private var errorView: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("加载失败")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(entry.errorMessage ?? "请检查网络连接")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
