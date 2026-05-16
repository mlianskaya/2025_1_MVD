import Foundation

struct DailyAmountDB: Codable, Equatable {
    var amountsByUid: [String: [String: Int]] = [:]
}

enum DayKey {

    static func make(from date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func addDays(_ days: Int, to date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func daysBetween(_ start: Date, _ end: Date, calendar: Calendar = .current) -> Int {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: s, to: e).day ?? 0
    }
}

actor DailyAmountStore {
    static let shared = DailyAmountStore()

    private let storageKey = "local.dailyAmounts.v1"
    private var db: DailyAmountDB = .init()
    private var loaded = false

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true

        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            db = .init()
            return
        }
        do {
            db = try JSONDecoder().decode(DailyAmountDB.self, from: data)
        } catch {
            db = .init()
            print("DailyAmountStore decode error:", error)
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(db)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("DailyAmountStore persist error:", error)
        }
    }

    func add(uid: String, date: Date, delta: Int) {
        ensureLoaded()
        let key = DayKey.make(from: date)

        var userMap = db.amountsByUid[uid] ?? [:]
        userMap[key, default: 0] += delta
        db.amountsByUid[uid] = userMap

        persist()
    }

    func get(uid: String, date: Date) -> Int {
        ensureLoaded()
        let key = DayKey.make(from: date)
        return db.amountsByUid[uid]?[key] ?? 0
    }

    func getAll(uid: String) -> [String: Int] {
        ensureLoaded()
        return db.amountsByUid[uid] ?? [:]
    }

    func clear(uid: String) {
        ensureLoaded()
        db.amountsByUid.removeValue(forKey: uid)
        persist()
    }
}
