import SwiftUI

/// 设置视图
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var refreshInterval: Int
    @State private var lowBalanceThreshold: Double
    @State private var notificationsEnabled: Bool

    private let storage = SharedStorageService.shared

    init() {
        let settings = SharedStorageService.shared.getSettings()
        _refreshInterval = State(initialValue: settings.refreshIntervalMinutes)
        _lowBalanceThreshold = State(initialValue: settings.lowBalanceThreshold)
        _notificationsEnabled = State(initialValue: settings.notificationsEnabled)
    }

    var body: some View {
        Form {
            // 刷新设置
            Section {
                Picker("刷新间隔", selection: $refreshInterval) {
                    Text("1 分钟").tag(1)
                    Text("5 分钟").tag(5)
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("60 分钟").tag(60)
                }
                .onChange(of: refreshInterval) { _, newValue in
                    storage.refreshIntervalMinutes = newValue
                    storage.bumpWidgetCacheToken()
                    storage.reloadWidgets()
                }
            } header: {
                Text("自动刷新")
            } footer: {
                Text("设置自动获取余额的时间间隔")
            }

            // 通知设置
            Section {
                Toggle("启用余额预警通知", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        storage.notificationsEnabled = newValue
                        if newValue {
                            Task {
                                await NotificationService.shared.requestPermission()
                            }
                        }
                    }

                if notificationsEnabled {
                    HStack {
                        Text("余额阈值")
                        Spacer()
                        TextField("", value: $lowBalanceThreshold, format: .currency(code: "CNY"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: lowBalanceThreshold) { _, newValue in
                                storage.lowBalanceThreshold = newValue
                            }
                    }
                }
            } header: {
                Text("通知")
            } footer: {
                Text("当余额低于阈值时发送系统通知")
            }

            // 账户信息
            Section {
                if authViewModel.isLoggedIn {
                    HStack {
                        Text("登录状态")
                        Spacer()
                        Text("已登录")
                            .foregroundColor(.green)
                    }

                    Button(role: .destructive) {
                        authViewModel.logout()
                    } label: {
                        Text("退出登录")
                    }
                } else {
                    HStack {
                        Text("登录状态")
                        Spacer()
                        Text("未登录")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("账户")
            }

            // 关于
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Link(destination: URL(string: "https://aicodemirror.com")!) {
                    HStack {
                        Text("访问 AICodeMirror")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("关于")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
