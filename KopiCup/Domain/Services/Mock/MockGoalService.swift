import SwiftUI
import Combine

final class MockGoalService: GoalService {

    @Published private var goal: Goal?
    @Published private var series: Series = Series(
        streakDays: 5,
        weekProgress: [true, true, true, false, false, false, false],
        lastAddedDate: Date()
    )

    private var cancellables = Set<AnyCancellable>()

    func observeGoal(_ handler: @escaping (Goal?) -> Void) {
        $goal
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }

    func createGoal(_ goal: Goal) {
        self.goal = goal
    }

    func updateGoal(_ goal: Goal) {
        self.goal = goal
    }

    func deleteGoal() {
        self.goal = nil
    }

    func addMoney(_ amount: Int) {
        guard var g = goal else { return }

        g.currentAmount += amount
        self.goal = g

        let dayIdx = Calendar.current.component(.weekday, from: Date()) - 1
        var prog = series.weekProgress
        if dayIdx >= 0 && dayIdx < prog.count {
            prog[dayIdx] = true
        }

        self.series = Series(
            streakDays: series.streakDays,
            weekProgress: prog,
            lastAddedDate: Date()
        )
    }

    func addMoney(_ amount: Int, forDayIndex dayIndex: Int) {
        guard var g = goal else { return }

        g.currentAmount += amount
        self.goal = g

        var prog = series.weekProgress
        if dayIndex >= 0 && dayIndex < prog.count {
            prog[dayIndex] = true
        }

        self.series = Series(
            streakDays: series.streakDays,
            weekProgress: prog,
            lastAddedDate: Date()
        )
    }

    func observeSeries(_ handler: @escaping (Series) -> Void) {
        $series
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }

    func updateSeries(_ series: Series) {
        self.series = series
    }
}
