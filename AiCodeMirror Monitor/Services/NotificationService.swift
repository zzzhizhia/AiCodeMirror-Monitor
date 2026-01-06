import Foundation
import UserNotifications

/// 通知服务 - 余额预警通知
final class NotificationService {
    static let shared = NotificationService()

    private let storage = SharedStorageService.shared
    private let center = UNUserNotificationCenter.current()

    // 避免重复通知的时间间隔 (24 小时)
    private let notificationCooldown: TimeInterval = 24 * 60 * 60

    private init() {}

    // MARK: - Permission

    /// 请求通知权限
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("通知权限请求失败: \(error)")
            return false
        }
    }

    /// 检查通知权限状态
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Low Balance Notification

    /// 发送余额不足通知
    func sendLowBalanceNotification(balance: Double, threshold: Double) {
        guard canSendNotification() else { return }

        let content = UNMutableNotificationContent()
        content.title = "余额不足提醒"
        content.body = String(format: "您的 AICodeMirror 余额为 $%.2f，已低于 $%.2f 阈值，请及时充值。", balance, threshold)
        content.sound = .default
        content.categoryIdentifier = "LOW_BALANCE"

        let request = UNNotificationRequest(
            identifier: "low_balance_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // 立即发送
        )

        center.add(request) { [weak self] error in
            if error == nil {
                self?.storage.saveLastNotificationDate(Date())
            }
        }
    }

    /// 发送订阅额度不足通知
    func sendLowSubscriptionNotification(remaining: Double, total: Double, planName: String) {
        guard canSendNotification() else { return }

        let percentage = (remaining / total) * 100

        let content = UNMutableNotificationContent()
        content.title = "订阅额度不足提醒"
        content.body = String(format: "您的 %@ 套餐剩余 %.0f%%（%.0f/%.0f），请注意使用。", planName, percentage, remaining, total)
        content.sound = .default
        content.categoryIdentifier = "LOW_SUBSCRIPTION"

        let request = UNNotificationRequest(
            identifier: "low_subscription_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request) { [weak self] error in
            if error == nil {
                self?.storage.saveLastNotificationDate(Date())
            }
        }
    }

    // MARK: - Private Methods

    /// 检查是否可以发送通知 (避免频繁打扰)
    private func canSendNotification() -> Bool {
        guard storage.notificationsEnabled else { return false }

        if let lastNotification = storage.getLastNotificationDate() {
            let timeSinceLastNotification = Date().timeIntervalSince(lastNotification)
            return timeSinceLastNotification > notificationCooldown
        }

        return true
    }

    // MARK: - Clear Notifications

    /// 清除所有待发送的通知
    func clearPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// 清除所有已发送的通知
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - Notification Categories

extension NotificationService {
    /// 注册通知分类 (可选，用于添加操作按钮)
    func registerCategories() {
        let lowBalanceCategory = UNNotificationCategory(
            identifier: "LOW_BALANCE",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_APP",
                    title: "打开应用",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "忽略",
                    options: .destructive
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let lowSubscriptionCategory = UNNotificationCategory(
            identifier: "LOW_SUBSCRIPTION",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_APP",
                    title: "打开应用",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "忽略",
                    options: .destructive
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([lowBalanceCategory, lowSubscriptionCategory])
    }
}
