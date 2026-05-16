import Foundation

struct AppActivityDB: Codable, Equatable {
    var activeDayKeysByUid: [String: Set<String>] = [:]
}

actor AppActivityStore {
    static let shared = AppActivityStore()

    private let storageKey = "local.appActivity.v1"
    private var db: AppActivityDB = .init()
    private var loaded = false

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true

        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            db = .init()
            return
        }

        do {
            db = try JSONDecoder().decode(AppActivityDB.self, from: data)
        } catch {
            db = .init()
            print("AppActivityStore decode error:", error)
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(db)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("AppActivityStore persist error:", error)
        }
    }

    func markAppOpen(uid: String, date: Date = Date()) {
        ensureLoaded()
        let key = DayKey.make(from: date)

        var set = db.activeDayKeysByUid[uid] ?? []
        set.insert(key)
        db.activeDayKeysByUid[uid] = set

        persist()
    }

    func getAll(uid: String) -> Set<String> {
        ensureLoaded()
        return db.activeDayKeysByUid[uid] ?? []
    }

    func clear(uid: String) {
        ensureLoaded()
        db.activeDayKeysByUid.removeValue(forKey: uid)
        persist()
    }
}
