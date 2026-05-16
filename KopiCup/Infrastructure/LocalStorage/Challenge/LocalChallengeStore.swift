import Foundation

final class LocalChallengeStore {
    static let shared = LocalChallengeStore()
    private let ud = UserDefaults.standard
    private init() {}

    private(set) var activeUID: String = "local"
    func setActive(uid: String?) { activeUID = uid ?? "local" }

    func loadActive() -> UserChallengeState? {
        load(uid: activeUID)
    }

    func saveActive(_ state: UserChallengeState?) {
        save(state, uid: activeUID)
    }

    private var observers: [(UserChallengeState?) -> Void] = []

    private func key(_ uid: String) -> String { "challenge.active.\(uid)" }

    func load(uid: String) -> UserChallengeState? {
        guard let data = ud.data(forKey: key(uid)) else { return nil }
        return try? JSONDecoder().decode(UserChallengeState.self, from: data)
    }

    func save(_ state: UserChallengeState?, uid: String) {
        if let state {
            let data = try? JSONEncoder().encode(state)
            ud.set(data, forKey: key(uid))
        } else {
            ud.removeObject(forKey: key(uid))
        }
        notify(state)
    }

    func observe(_ block: @escaping (UserChallengeState?) -> Void) {
        observers.append(block)
    }

    private func notify(_ state: UserChallengeState?) {
        observers.forEach { $0(state) }
    }
}
