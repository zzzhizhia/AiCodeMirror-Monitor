import SwiftUI
import WidgetKit
import AppKit

@main
struct AICodeMirrorMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                    // 当窗口关闭时，检查是否还有其他可见窗口
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let hasVisibleWindows = NSApp.windows.contains { window in
                            window.isVisible && !window.title.isEmpty && window.level == .normal
                        }
                        if !hasVisibleWindows {
                            // 没有可见窗口时，隐藏 Dock 图标
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                }
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

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 监听窗口显示事件，当窗口显示时恢复 Dock 图标
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeVisible),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    @objc func windowDidBecomeVisible(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        // 如果是主窗口（非菜单栏窗口）显示，恢复 Dock 图标
        if window.level == .normal && !window.title.isEmpty {
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当用户点击 Dock 图标时，如果没有可见窗口，显示主窗口
        if !flag {
            NSApp.setActivationPolicy(.regular)
        }
        return true
    }
}
