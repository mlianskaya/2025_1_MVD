import SwiftUI
import Combine

final class SeriesViewModel: ObservableObject {
    @Published var series: Series?
    @Published var dailyTarget: Int = 0
    @Published var todayAddedAmount: Int = 0
    @Published var showAddMoneyModal = false
    @Published var selectedDayIndex: Int? = nil
    @Published var perDayAdded: [Int] = Array(repeating: 0, count: 7)

    // Глобальная валюта отображения
    @Published var currencyCode: String = UserDefaults.standard.string(forKey: "settings.currency.code") ?? "RUB"

    @Published var goal: Goal? = nil

    private let goalService: GoalService
    private let uid: String
    private let rewardService = RewardService.shared
    private var cancellables = Set<AnyCancellable>()
    private var udObserver: NSObjectProtocol?

    // MARK: - Persistence
    private let ud = UserDefaults.standard
    private enum Keys {
        static let perDayAdded = "series.perDayAdded"
        static let weekProgress = "series.weekProgress"
        static let streakDays = "series.streakDays"
        static let lastAddedDate = "series.lastAddedDate"
    }

    init(goalService: GoalService, uid: String) {
        self.goalService = goalService
        self.uid = uid

        loadPersistedState()
        rollWeekIfNeeded()

        if perDayAdded.indices.contains(currentDayIndex) {
            todayAddedAmount = perDayAdded[currentDayIndex]
        }

        // Слушаем активную цель (но больше не подменяем валюту из goal.currency)
        goalService.observeGoal { [weak self] goal in
            DispatchQueue.main.async {
                self?.goal = goal
            }
        }

        // Реагируем на смену глобальной валюты в профиле
        udObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let newCode = UserDefaults.standard.string(forKey: "settings.currency.code") ?? "RUB"
            if newCode != self.currencyCode {
                self.currencyCode = newCode
            }
        }
    }

    deinit {
        if let udObserver {
            NotificationCenter.default.removeObserver(udObserver)
        }
    }

    var totalSavedThisWeek: Int {
        perDayAdded.reduce(0, +)
    }

    var savedDaysCount: Int {
        guard let progress = series?.weekProgress else { return 0 }
        return progress.filter { $0 }.count
    }

    var currentDayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }

    func addMoney(_ amountMinorUnits: Int) {
        addMoney(amountMinorUnits, for: currentDayIndex)
    }

    func addMoney(_ amountMinorUnits: Int, for dayIndex: Int) {
        guard amountMinorUnits > 0 else { return }
        guard dayIndex == currentDayIndex else { return }

        let didCompleteGoal = willCompleteGoal(with: amountMinorUnits)

        let previousProgress = series?.weekProgress ?? Array(repeating: false, count: 7)
        let wasWeekAlreadyComplete = previousProgress.allSatisfy { $0 }

        goalService.addMoney(amountMinorUnits)

        guard dayIndex >= 0, dayIndex < perDayAdded.count else { return }
        perDayAdded[dayIndex] += amountMinorUnits

        if dayIndex == currentDayIndex {
            todayAddedAmount = perDayAdded[dayIndex]
        }

        if let s = series {
            var newProgress = s.weekProgress
            var newStreak = s.streakDays

            if dayIndex >= 0, dayIndex < newProgress.count, newProgress[dayIndex] == false {
                newProgress[dayIndex] = true
                newStreak += 1
            }

            series = Series(
                streakDays: newStreak,
                weekProgress: newProgress,
                lastAddedDate: Date()
            )
        } else {
            var newProgress = Array(repeating: false, count: 7)
            newProgress[dayIndex] = true
            series = Series(
                streakDays: 1,
                weekProgress: newProgress,
                lastAddedDate: Date()
            )
        }

        savePerDayAdded()
        saveSeriesCoreState()

        let isWeekNowComplete = series?.weekProgress.allSatisfy { $0 } ?? false
        let didCompleteWeek = !wasWeekAlreadyComplete && isWeekNowComplete

        Task {
            await claimRewardsIfNeeded(
                didCompleteGoal: didCompleteGoal,
                didCompleteWeek: didCompleteWeek
            )
        }
    }

    func completeGoal() {
        let remaining = max(dailyTarget - todayAddedAmount, 0)
        guard remaining > 0 else { return }
        addMoney(remaining, for: currentDayIndex)
    }

    var canCloseGoal: Bool {
        dailyTarget > 0 && todayAddedAmount < dailyTarget
    }

    var remainingAmountText: String {
        let remaining = max(dailyTarget - todayAddedAmount, 0)
        return formatWithCurrentCurrency(remaining)
    }

    var remainingToGoal: Int {
        guard let g = goal else { return 0 }
        return max(g.targetAmount - g.currentAmount, 0)
    }

    var remainingToGoalText: String {
        formatWithCurrentCurrency(remainingToGoal)
    }

    var canCloseFullGoal: Bool {
        remainingToGoal > 0
    }

    func closeFullGoal() {
        let remaining = remainingToGoal
        guard remaining > 0 else { return }
        addMoney(remaining, for: currentDayIndex)
    }

    func isDayCompleted(_ dayIndex: Int) -> Bool {
        guard let progress = series?.weekProgress,
              dayIndex >= 0, dayIndex < progress.count else { return false }
        return progress[dayIndex]
    }

    // Форматирование по текущей глобальной валюте
    func formatWithCurrentCurrency(_ minorUnits: Int) -> String {
        let value = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) \(currencyCode)"
    }

    private func loadPersistedState() {
        if let arr = ud.array(forKey: key(Keys.perDayAdded)) as? [Int] {
            if arr.count == 7 {
                perDayAdded = arr
            } else {
                perDayAdded = Array(arr.prefix(7)) + Array(repeating: 0, count: max(0, 7 - arr.count))
            }
        }

        let weekProgress = (ud.array(forKey: key(Keys.weekProgress)) as? [Bool]) ?? Array(repeating: false, count: 7)
        let streakDays = ud.integer(forKey: key(Keys.streakDays))
        let lastTime = ud.double(forKey: key(Keys.lastAddedDate))
        let lastDate = lastTime > 0 ? Date(timeIntervalSince1970: lastTime) : Date.distantPast

        if weekProgress.contains(true) || streakDays > 0 || lastTime > 0 {
            series = Series(
                streakDays: streakDays,
                weekProgress: weekProgress.count == 7 ? weekProgress : Array(weekProgress.prefix(7)) + Array(repeating: false, count: max(0, 7 - weekProgress.count)),
                lastAddedDate: lastDate
            )
        }
    }

    private func key(_ suffix: String) -> String {
        "user.\(uid)." + suffix
    }

    private func savePerDayAdded() {
        ud.set(perDayAdded, forKey: key(Keys.perDayAdded))
    }

    private func saveSeriesCoreState() {
        guard let s = series else { return }
        ud.set(s.weekProgress, forKey: key(Keys.weekProgress))
        ud.set(s.streakDays, forKey: key(Keys.streakDays))
        ud.set((s.lastAddedDate ?? Date.distantPast).timeIntervalSince1970, forKey: key(Keys.lastAddedDate))
    }

    private func rollWeekIfNeeded() {
        guard let s = series else { return }
        let now = Date()
        let last = s.lastAddedDate ?? Date.distantPast

        if !isSameWeek(last, now) {
            perDayAdded = Array(repeating: 0, count: 7)
            todayAddedAmount = 0
            series = Series(
                streakDays: s.streakDays,
                weekProgress: Array(repeating: false, count: 7),
                lastAddedDate: now
            )
            savePerDayAdded()
            saveSeriesCoreState()
        }
    }

    private func isSameWeek(_ d1: Date, _ d2: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.weekOfYear, from: d1) == cal.component(.weekOfYear, from: d2)
            && cal.component(.yearForWeekOfYear, from: d1) == cal.component(.yearForWeekOfYear, from: d2)
    }

    private func preferSeries(local: Series, remote: Series) -> Series {
        let localDate = local.lastAddedDate ?? .distantPast
        let remoteDate = remote.lastAddedDate ?? .distantPast

        if remoteDate > localDate {
            return remote
        } else if remoteDate < localDate {
            return local
        } else {
            let localCount = local.weekProgress.filter { $0 }.count
            let remoteCount = remote.weekProgress.filter { $0 }.count
            return remoteCount >= localCount ? remote : local
        }
    }

    private func willCompleteGoal(with addedAmount: Int) -> Bool {
        guard let goal else { return false }
        guard let goalId = goal.id, !goalId.isEmpty else { return false }
        guard goal.targetAmount > 0 else { return false }

        let oldAmount = goal.currentAmount
        let newAmount = oldAmount + addedAmount

        return oldAmount < goal.targetAmount && newAmount >= goal.targetAmount
    }

    private func makeWeekRewardKey(from date: Date) -> String {
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    private func claimRewardsIfNeeded(
        didCompleteGoal: Bool,
        didCompleteWeek: Bool
    ) async {
        if didCompleteGoal, let goalId = goal?.id {
            do {
                _ = try await rewardService.claimGoalCompleted(goalId: goalId)
            } catch {
                print("SeriesViewModel goal reward error:", error)
            }
        }

        if didCompleteWeek {
            let weekKey = makeWeekRewardKey(from: Date())
            do {
                _ = try await rewardService.claimWeeklyStreak(weekKey: weekKey)
            } catch {
                print("SeriesViewModel weekly streak reward error:", error)
            }
        }
    }
}
