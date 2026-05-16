import Foundation

enum DailyAmountError: Error, LocalizedError {
    case notSignedIn
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Пользователь не авторизован"
        case .invalidAmount: return "Некорректная сумма"
        }
    }
}

final class DailyAmountService {
    private let store: DailyAmountStore

    init(store: DailyAmountStore = .shared) {
        self.store = store
    }

    private var uid: String? { LocalUserStore.shared.activeUID }

    func addToday(amount: Int) async throws {
        guard let uid else { throw DailyAmountError.notSignedIn }
        guard amount > 0 else { throw DailyAmountError.invalidAmount }
        await store.add(uid: uid, date: Date(), delta: amount)
    }

    func amountForToday() async throws -> Int {
        guard let uid else { throw DailyAmountError.notSignedIn }
        return await store.get(uid: uid, date: Date())
    }

    func amount(for date: Date) async throws -> Int {
        guard let uid else { throw DailyAmountError.notSignedIn }
        return await store.get(uid: uid, date: date)
    }

    func allDays() async throws -> [String: Int] {
        guard let uid else { throw DailyAmountError.notSignedIn }
        return await store.getAll(uid: uid)
    }
    func add(amount: Int, for date: Date) async throws {
        guard let uid else { throw DailyAmountError.notSignedIn }
        guard amount > 0 else { throw DailyAmountError.invalidAmount }
        await store.add(uid: uid, date: date, delta: amount)
    }
}
