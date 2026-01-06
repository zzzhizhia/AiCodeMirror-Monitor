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
            // 标题
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("余额")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 主要余额显示
            if let paygo = balance.payAsYouGoBalance {
                VStack(alignment: .leading, spacing: 2) {
                    Text(paygo.formattedBalance)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)

                    Text("按量付费")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else if let sub = balance.subscriptionBalance {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(sub.remainingAmount))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("\(sub.planName) 剩余")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
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
