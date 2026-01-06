import SwiftUI
import WidgetKit

@main
struct AICodeMirrorMonitorApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var balanceViewModel = BalanceViewModel()

    init() {
        // 注册通知分类
        NotificationService.shared.registerCategories()

        // 请求通知权限
        Task {
            await NotificationService.shared.requestPermission()
        }
    }

    var body: some Scene {
        // 主窗口
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(balanceViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 450)

        // 设置窗口
        Settings {
            SettingsView()
                .environmentObject(authViewModel)
        }

        // 菜单栏
        MenuBarExtra("AICodeMirror", systemImage: "creditcard.fill") {
            MenuBarView()
                .environmentObject(authViewModel)
                .environmentObject(balanceViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
