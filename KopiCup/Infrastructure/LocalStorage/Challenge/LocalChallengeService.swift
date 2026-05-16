import Foundation
import Combine
import FirebaseAuth

final class LocalChallengeService: ChallengeService {

    @Published private var userChallenge: UserChallenge?

    private var cancellables = Set<AnyCancellable>()
    private let store: LocalChallengeStore
    private var challenges: [Challenge] = []

    init(store: LocalChallengeStore = .shared) {
        self.store = store

        store.observe { [weak self] _ in
            self?.refreshFromStore()
        }
    }

    func loadChallenges(completion: @escaping ([Challenge]) -> Void) {
        let list = [
            Challenge(id: "1", name: "Не покупать кофе", description: "Попробуй день без кофе", difficulty: 1),
            Challenge(id: "2", name: "Прогулка 5км", description: "Ходи пешком", difficulty: 2),
            Challenge(id: "3", name: "Без сахара", description: "Никаких сладостей", difficulty: 3)
        ]

        self.challenges = list
        completion(list)

        refreshFromStore()
    }

    func observeUserChallenge(_ handler: @escaping (UserChallenge?) -> Void) {
        $userChallenge
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }

    func startChallenge(_ challenge: Challenge) {
        let state = UserChallengeState(
            challengeId: challenge.id,
            startDate: Date(),
            completedDayKeys: []
        )
        store.saveActive(state)
    }

    func declineChallenge() {
        store.saveActive(nil)
    }

    func markDayComplete() {
        guard var state = store.loadActive() else { return }

        let dayIndex = daysBetween(start: state.startDate, end: Date())
        guard (0...6).contains(dayIndex) else { return }

        let todayKey = DayKey.make(from: Date())
        guard !state.completedDayKeys.contains(todayKey) else { return }

        state.completedDayKeys.insert(todayKey)
        store.saveActive(state)

        let completedDaysCount = state.completedDayKeys.count
        guard completedDaysCount >= 7 else { return }
        guard let challenge = challenges.first(where: { $0.id == state.challengeId }) else { return }

        Task {
            do {
                _ = try await RewardService.shared.claimChallengeCompleted(
                    challengeId: challenge.id,
                    startDate: state.startDate,
                    difficulty: challenge.difficulty
                )
            } catch {
                print("LocalChallengeService reward error:", error)
            }
        }
    }

    // MARK: - Private

    private func refreshFromStore() {
        let state = store.loadActive()
        DispatchQueue.main.async {
            self.userChallenge = self.makeUserChallenge(from: state)
        }
    }

    private func makeUserChallenge(from state: UserChallengeState?) -> UserChallenge? {
        guard let state else { return nil }
        guard let challenge = challenges.first(where: { $0.id == state.challengeId }) else { return nil }

        let progress = (0..<7).map { offset -> Bool in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: state.startDate) ?? state.startDate
            let key = DayKey.make(from: date)
            return state.completedDayKeys.contains(key)
        }

        return UserChallenge(challenge: challenge, startDate: state.startDate, progress: progress)
    }

    private func daysBetween(start: Date, end: Date) -> Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        return cal.dateComponents([.day], from: s, to: e).day ?? 0
    }
}
