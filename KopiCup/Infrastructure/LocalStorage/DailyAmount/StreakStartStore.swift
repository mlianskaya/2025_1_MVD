import Foundation

actor StreakStartStore {
    static let shared = StreakStartStore()

    private let key = "local.streakStartByUid.v1"
    private var loaded = false
    private var map: [String: Date] = [:]

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true

        guard let data = UserDefaults.standard.data(forKey: key) else {
            map = [:]
            return
        }

        do {
            map = try JSONDecoder().decode([String: Date].self, from: data)
        } catch {
            map = [:]
            print("StreakStartStore decode error:", error)
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(map)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("StreakStartStore persist error:", error)
        }
    }

    func get(uid: String) -> Date? {
        ensureLoaded()
        return map[uid]
    }

    func set(uid: String, date: Date) {
        ensureLoaded()
        map[uid] = date
        persist()
    }

    func clear(uid: String) {
        ensureLoaded()
        map.removeValue(forKey: uid)
        persist()
    }
}
