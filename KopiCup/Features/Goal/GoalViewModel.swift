import SwiftUI
import Combine

extension Notification.Name {
    static let didDeposit = Notification.Name("KopiCup.didDeposit")
}

final class GoalViewModel: ObservableObject {
    @Published var currentGoal: Goal?
    @Published var showAddModal = false
    @Published var showDetailsModal = false
    @Published var showEditModal = false

    private let goalService: GoalService
    private var cancellables = Set<AnyCancellable>()

    init(goalService: GoalService) {
        self.goalService = goalService

        goalService.observeGoal { [weak self] goal in
            DispatchQueue.main.async { self?.currentGoal = goal }
        }

        NotificationCenter.default.publisher(for: .didDeposit)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let amount = notification.userInfo?["amount"] as? Int else { return }
                self?.currentGoal?.currentAmount += amount
            }
            .store(in: &cancellables)
    }

    func createGoal(_ goal: Goal) {
        DispatchQueue.main.async { self.currentGoal = goal }
        goalService.createGoal(goal)
    }

    func updateGoal(_ goal: Goal) {
        DispatchQueue.main.async { self.currentGoal = goal }
        goalService.updateGoal(goal)
    }

    func deleteGoal() {
        DispatchQueue.main.async { self.currentGoal = nil }
        goalService.deleteGoal()
    }

    var progress: Double {
        currentGoal?.progress ?? 0
    }

    var remaining: Int {
        guard let goal = currentGoal else { return 0 }
        return max(goal.targetAmount - goal.currentAmount, 0)
    }
}
