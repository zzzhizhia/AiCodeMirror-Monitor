import SwiftUI
import WidgetKit

/// 仪表板视图
struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var balanceViewModel: BalanceViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部
                headerSection

                // 余额卡片
                if let balance = balanceViewModel.balance {
                    balanceCardsSection(balance: balance)
                } else if balanceViewModel.isLoading {
                    loadingSection
                } else if let error = balanceViewModel.error {
                    errorSection(error: error)
                } else {
                    emptySection
                }

                Spacer(minLength: 20)

                // 操作按钮
                actionsSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("账户概览")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let lastUpdate = balanceViewModel.balance?.lastUpdated {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("更新于 \(lastUpdate, style: .relative)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                balanceViewModel.refresh()
            }) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(balanceViewModel.isLoading)
        }
    }

    // MARK: - Balance Cards

    @ViewBuilder
    private func balanceCardsSection(balance: AccountBalance) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 按量付费卡片
                if let paygo = balance.payAsYouGoBalance {
                    PayGoBalanceCard(balance: paygo)
                }

                // 订阅卡片
                if let sub = balance.subscriptionBalance {
                    SubscriptionBalanceCard(subscription: sub)
                }
            }

            // 用户信息
            if let user = balance.userIdentifier {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.secondary)
                    Text(user)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("正在获取余额...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error

    private func errorSection(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("获取余额失败")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("重试") {
                balanceViewModel.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Empty

    private var emptySection: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("暂无数据")
                .font(.headline)

            Text("点击刷新按钮获取最新余额")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                if let url = URL(string: "https://aicodemirror.com/dashboard") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("打开网站", systemImage: "safari")
            }

            Button(action: {
                WidgetCenter.shared.reloadAllTimelines()
            }) {
                Label("刷新 Widget", systemImage: "widget.small")
            }

            Spacer()

            Button(role: .destructive, action: {
                authViewModel.logout()
            }) {
                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .padding(.top)
    }
}

// MARK: - Balance Cards

struct PayGoBalanceCard: View {
    let balance: PayAsYouGoBalance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                Text("按量付费")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(balance.formattedBalance)
                .font(.system(size: 32, weight: .bold))

            if let spent = balance.monthlySpent {
                HStack {
                    Text("本月消费")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f %@", spent, balance.currency))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SubscriptionBalanceCard: View {
    let subscription: SubscriptionBalance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
                Text(subscription.planName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if let resetDate = subscription.resetDate {
                    Text("重置: \(resetDate, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(Int(subscription.remainingAmount))")
                    .font(.system(size: 32, weight: .bold))

                Text("/ \(Int(subscription.totalAmount)) \(subscription.unit)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: 1 - subscription.usagePercentage)
                    .tint(progressColor)

                HStack {
                    Text("已使用 \(Int(subscription.usagePercentage * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("剩余 \(Int((1 - subscription.usagePercentage) * 100))%")
                        .font(.caption)
                        .foregroundColor(progressColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var progressColor: Color {
        let remaining = 1 - subscription.usagePercentage
        if remaining < 0.2 {
            return .red
        } else if remaining < 0.4 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(BalanceViewModel())
        .frame(width: 600, height: 500)
}
