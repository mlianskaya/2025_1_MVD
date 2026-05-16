import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseGoalService: GoalService {

    private let repo = GoalsRepository()
    private let db = Firestore.firestore()

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?
    private var goalListener: ListenerRegistration?
    private var seriesListener: ListenerRegistration?

    private var currentGoalId: String?
    
    private let dailyAmountService = DailyAmountService()
    private let streakStartStore = StreakStartStore.shared

    deinit {
        stopAllListening()
    }

    // MARK: - Observe Goal

    func observeGoal(_ handler: @escaping (Goal?) -> Void) {
        // Сбрасываем предыдущие слушатели
        stopAllListening()

        // Если пользователь уже есть — сразу стартуем
        if let uid = Auth.auth().currentUser?.uid {
            listenUserDoc(uid: uid, handler: handler)
        } else {
            // Сообщим вью‑модели текущее отсутствие цели (можно убрать, если не хотите моргания)
            handler(nil)
        }

        // Подпишемся на изменения состояния аутентификации
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let uid = user?.uid {
                self.listenUserDoc(uid: uid, handler: handler)
            } else {
                // Логаут: чистим все и отдаем nil
                self.stopUserListening()
                self.stopGoalListening()
                self.currentGoalId = nil
                handler(nil)
            }
        }
    }

    private func listenUserDoc(uid: String, handler: @escaping (Goal?) -> Void) {
        stopUserListening()

        userListener = FirestorePaths.userDoc(uid: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }

                guard
                    let data = snapshot?.data(),
                    let goalId = data["activeGoalId"] as? String
                else {
                    self.stopGoalListening()
                    self.currentGoalId = nil
                    handler(nil)
                    return
                }

                if self.currentGoalId != goalId {
                    self.currentGoalId = goalId
                    self.listenGoal(uid: uid, goalId: goalId, handler: handler)
                }
            }
    }

    private func listenGoal(uid: String, goalId: String, handler: @escaping (Goal?) -> Void) {
        stopGoalListening()

        goalListener = FirestorePaths.goal(uid: uid, goalId: goalId)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else {
                    handler(nil)
                    return
                }

                let goal = try? snapshot.data(as: Goal.self)
                handler(goal)
            }
    }

    private func stopUserListening() {
        userListener?.remove()
        userListener = nil
    }

    private func stopGoalListening() {
        goalListener?.remove()
        goalListener = nil
    }

    private func stopAllListening() {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        authHandle = nil
        stopUserListening()
        stopGoalListening()
    }

    // MARK: - Mutations

    func createGoal(_ goal: Goal) {
        Task {
            do {
                _ = try await repo.createGoal(goal, setAsActive: true)
            } catch {
                print("createGoal error:", error)
            }
        }
    }

    func updateGoal(_ goal: Goal) {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let goalId = goal.id
        else { return }

        Task {
            do {
                try FirestorePaths.goal(uid: uid, goalId: goalId)
                    .setData(from: goal, merge: true)
            } catch {
                print("updateGoal error:", error)
            }
        }
    }

    func deleteGoal() {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let goalId = currentGoalId
        else { return }

        Task {
            do {
                try await FirestorePaths.goal(uid: uid, goalId: goalId).delete()
                try await FirestorePaths.userDoc(uid: uid).updateData([
                    "activeGoalId": FieldValue.delete()
                ])
            } catch {
                print("deleteGoal error:", error)
            }
        }
    }

    func addMoney(_ amount: Int) {
        guard let goalId = currentGoalId else { return }

        Task {
            do {
                try await repo.addTransaction(
                    goalId: goalId,
                    type: "deposit",
                    amount: amount
                )

                try await dailyAmountService.addToday(amount: amount)

                NotificationCenter.default.post(
                    name: .didDeposit,
                    object: nil,
                    userInfo: ["amount": amount]
                )
            } catch {
                print("addMoney error:", error)
            }
        }
    }
    
    enum DayMath {
        static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
            calendar.startOfDay(for: date)
        }

        static func addDays(_ date: Date, days: Int, calendar: Calendar = .current) -> Date {
            calendar.date(byAdding: .day, value: days, to: date) ?? date
        }
    }

    func addMoney(_ amount: Int, forDayIndex dayIndex: Int) {
        guard let goalId = currentGoalId else { return }

        Task {
            do {
                try await repo.addTransaction(
                    goalId: goalId,
                    type: "deposit",
                    amount: amount
                )

                guard let uid = LocalUserStore.shared.activeUID else { return }

                let start: Date
                if let saved = await streakStartStore.get(uid: uid) {
                    start = DayMath.startOfDay(saved)
                } else {
                    let today = DayMath.startOfDay(Date())
                    start = today
                    await streakStartStore.set(uid: uid, date: today)
                }

                let targetDay = DayMath.addDays(start, days: dayIndex)
                try await dailyAmountService.add(amount: amount, for: targetDay)

                NotificationCenter.default.post(
                    name: .didDeposit,
                    object: nil,
                    userInfo: ["amount": amount]
                )
            } catch {
                print("addMoney(forDayIndex:) error:", error)
            }
        }
    }

    // MARK: - Series stubs

    func observeSeries(_ handler: @escaping (Series) -> Void) {
        handler(
            Series(
                streakDays: 0,
                weekProgress: [false, false, false, false, false, false, false],
                lastAddedDate: nil
            )
        )
    }

    func updateSeries(_ series: Series) {
        // TODO: хранить Series в Firestore
    }
}
