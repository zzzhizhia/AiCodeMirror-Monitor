import SwiftUI
import WidgetKit

/// 大尺寸 Widget 视图 - macOS 原生风格
struct LargeWidgetView: View {
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
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("未登录")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text("点击打开 AICodeMirror Monitor")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("登录后即可查看余额")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func loggedInView(balance: AccountBalance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AICodeMirror")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let user = balance.userIdentifier {
                        Text(user)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            Divider()

            // 按量付费卡片
            if let paygo = balance.payAsYouGoBalance {
                VStack(alignment: .leading, spacing: 8) {
                    Label("按量付费 (PAYGO)", systemImage: "creditcard.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .bottom, spacing: 4) {
                        Text(paygo.formattedBalance)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("可用余额")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 4)
                    }

                    if let spent = paygo.monthlySpent {
                        HStack {
                            Text("本月消费")
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                            Text(String(format: "%.2f %@", spent, paygo.currency))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // 订阅卡片
            if let sub = balance.subscriptionBalance {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("\(sub.planName) 套餐", systemImage: "star.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        Spacer()

                        if let resetDate = sub.resetDate {
                            Text("重置: \(resetDate, style: .date)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("已使用")
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                            Spacer()

                            Text("\(Int(sub.usedAmount)) / \(Int(sub.totalAmount)) \(sub.unit)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: sub.usagePercentage)
                            .tint(progressColor(for: sub.usagePercentage))

                        HStack {
                            Text("剩余")
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                            Text("\(Int(sub.remainingAmount)) \(sub.unit)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(Int((1 - sub.usagePercentage) * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(progressColor(for: sub.usagePercentage))
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer(minLength: 0)
        }
        .padding()
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
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("数据加载失败")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(entry.errorMessage ?? "请检查网络连接或重新登录")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("点击打开 App 刷新")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
