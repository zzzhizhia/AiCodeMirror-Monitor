import SwiftUI

/// 菜单栏视图
struct MenuBarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var balanceViewModel: BalanceViewModel
    private let storage = SharedStorageService.shared

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if authViewModel.isLoggedIn {
                loggedInContent
            } else {
                notLoggedInContent
            }

            Divider()
                .padding(.vertical, 8)

            // 底部操作
            footerActions
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Logged In Content

    private var loggedInContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text("AICodeMirror")
                    .font(.headline)

                Spacer()

                if balanceViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button(action: {
                        balanceViewModel.refresh()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("刷新余额")
                }
            }

            if let balance = balanceViewModel.balance {
                // 按量付费余额
                if let paygo = balance.payAsYouGoBalance {
                    BalanceRow(
                        icon: "creditcard.fill",
                        iconColor: .blue,
                        title: "按量付费余额",
                        value: paygo.formattedBalance
                    )
                }

                // 订阅余额
                if let sub = balance.subscriptionBalance {
                    BalanceRow(
                        icon: "star.fill",
                        iconColor: .purple,
                        title: "订阅余额",
                        value: String(format: "¥%.2f", sub.remainingAmount)
                    )
                }

                // 更新时间
                HStack {
                    Spacer()

                    // WebView 标识
                    if balance.fetchMethod == .webview {
                        Text("🐢")
                            .font(.caption2)
                    }

                    Text("更新于 \(balance.lastUpdated, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if balanceViewModel.error != nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("获取失败")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("重试") {
                        balanceViewModel.refresh()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            } else {
                HStack {
                    Text("暂无数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("获取") {
                        balanceViewModel.refresh()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Not Logged In Content

    private var notLoggedInContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("未登录")
                .font(.headline)

            Text("请打开主窗口登录")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Footer Actions

    private var footerActions: some View {
        VStack(spacing: 8) {
            Button(action: {
                if let url = URL(string: "https://aicodemirror.com/dashboard") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "safari")
                    Text("打开网站")
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(action: {
                storage.bumpWidgetCacheToken()
                storage.reloadWidgets()
            }) {
                HStack {
                    Image(systemName: "widget.small")
                    Text("刷新 Widget")
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Divider()

            Button(action: {
                NSApp.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("退出")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Balance Row

struct BalanceRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AuthViewModel())
        .environmentObject(BalanceViewModel())
}
