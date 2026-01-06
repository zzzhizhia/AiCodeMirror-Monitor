import Foundation
import Combine
import WidgetKit
import AppKit

/// 余额视图模型
@MainActor
final class BalanceViewModel: ObservableObject {
    @Published private(set) var balance: AccountBalance?
    @Published private(set) var isLoading = false
    @Published var error: Error?

    private let balanceService = BalanceService()
    private let storage = SharedStorageService.shared
    private let notificationService = NotificationService.shared

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadCachedBalance()
        setupAppStateObserver()
    }

    // MARK: - Public Methods

    /// 获取余额
    func fetchBalance() {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let newBalance = try await balanceService.fetchBalance()

                self.balance = newBalance
                self.error = nil

                // 保存到共享存储
                try? storage.saveBalanceData(newBalance)
                storage.saveLastUpdateTime(Date())

                // 更新 Widget Entry
                let entry = WidgetBalanceEntry(
                    date: Date(),
                    balance: newBalance,
                    isLoggedIn: true,
                    errorMessage: nil
                )
                try? storage.saveWidgetEntry(entry)

                // 刷新 Widget
                WidgetCenter.shared.reloadAllTimelines()

                // 检查余额预警
                checkLowBalanceWarning(newBalance)

            } catch {
                self.error = error
            }

            isLoading = false
        }
    }

    /// 开始自动刷新
    func startAutoRefresh() {
        stopAutoRefresh()

        let intervalMinutes = storage.refreshIntervalMinutes
        let interval = TimeInterval(intervalMinutes * 60)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchBalance()
            }
        }

        // 立即执行一次
        fetchBalance()
    }

    /// 停止自动刷新
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// 手动刷新
    func refresh() {
        fetchBalance()
    }

    // MARK: - Private Methods

    private func loadCachedBalance() {
        balance = storage.getBalanceData()
    }

    private func setupAppStateObserver() {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkAndRefreshIfNeeded()
            }
            .store(in: &cancellables)
    }

    private func checkAndRefreshIfNeeded() {
        guard let lastUpdate = storage.getLastUpdateTime() else {
            fetchBalance()
            return
        }

        let refreshInterval = TimeInterval(storage.refreshIntervalMinutes * 60)
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)

        if timeSinceLastUpdate > refreshInterval {
            fetchBalance()
        }
    }

    private func checkLowBalanceWarning(_ balance: AccountBalance) {
        guard storage.notificationsEnabled else { return }

        let threshold = storage.lowBalanceThreshold

        // 检查按量付费余额
        if let paygo = balance.payAsYouGoBalance {
            if paygo.currentBalance < threshold {
                notificationService.sendLowBalanceNotification(
                    balance: paygo.currentBalance,
                    threshold: threshold
                )
            }
        }

        // 检查订阅余额
        if let sub = balance.subscriptionBalance {
            let remainingPercentage = (1 - sub.usagePercentage) * 100
            if remainingPercentage < 20 { // 剩余不足 20%
                notificationService.sendLowSubscriptionNotification(
                    remaining: sub.remainingAmount,
                    total: sub.totalAmount,
                    planName: sub.planName
                )
            }
        }
    }
}
