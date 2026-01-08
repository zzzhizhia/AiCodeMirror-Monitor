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

                // WebView 标识
                if balance.fetchMethod == .webview {
                    Text("🐢")
                        .font(.title3)
                        .help("使用 WebView 获取（较慢）")
                }
            }

            Divider()

            // 订阅卡片
            if let sub = balance.subscriptionBalance {
                VStack(alignment: .leading, spacing: 8) {
                    Label("订阅余额", systemImage: "star.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(String(format: "¥%.2f", sub.remainingAmount))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // 按量付费卡片
            if let paygo = balance.payAsYouGoBalance {
                VStack(alignment: .leading, spacing: 8) {
                    Label("按量付费余额", systemImage: "creditcard.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(paygo.formattedBalance)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.primary)
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
