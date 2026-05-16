import Foundation

final class LocalUserService: UserService {

    private let store: LocalUserStore

    init(store: LocalUserStore = .shared) {
        self.store = store
    }

    func fetchUser(completion: @escaping (User) -> Void) {
        let uid = store.activeUID ?? "local"
        let profile = store.getActiveProfile()

        let user = User(
            id: uid,
            name: profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Гость" : profile.name,
            photoURL: nil
        )
        completion(user)
    }

    func setActive(uid: String?) {
        store.setActive(uid: uid)
    }

    func fetchProfile() -> LocalProfile {
        store.getActiveProfile()
    }

    func updateName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var profile = store.getActiveProfile()
        profile.name = trimmed.isEmpty ? "Гость" : trimmed
        store.saveActiveProfile(profile)
    }

    func updateAvatarData(_ data: Data?) {
        var profile = store.getActiveProfile()
        profile.avatarData = (data?.isEmpty == true) ? nil : data
        store.saveActiveProfile(profile)
    }
}
