import Foundation

struct LocalProfile: Codable {
    var name: String
    var avatarData: Data?

    static let `default` = LocalProfile(name: "Гость", avatarData: nil)
}

final class LocalUserStore {
    static let shared = LocalUserStore()
    private init() {}

    private(set) var activeUID: String?

    private let profilesKey = "local.profiles.byUid.v1"
    private var cache: [String: LocalProfile] = [:]
    private var loaded = false

    // MARK: - Public

    func setActive(uid: String?) {
        ensureLoaded()
        activeUID = uid
    }

    func getActiveProfile() -> LocalProfile {
        ensureLoaded()
        guard let uid = activeUID else { return .default }
        return cache[uid] ?? .default
    }

    func saveActiveProfile(_ profile: LocalProfile) {
        ensureLoaded()
        guard let uid = activeUID else { return } // без uid некуда сохранять
        cache[uid] = profile
        persist()
    }

    func removeProfile(uid: String) {
        ensureLoaded()
        cache.removeValue(forKey: uid)
        persist()
    }

    // MARK: - Private

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true

        guard let data = UserDefaults.standard.data(forKey: profilesKey) else {
            cache = [:]
            return
        }

        do {
            cache = try JSONDecoder().decode([String: LocalProfile].self, from: data)
        } catch {
            cache = [:]
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(cache)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("LocalUserStore persist error:", error)
        }
    }
}
