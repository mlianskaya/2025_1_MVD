// LocalEconomyStore.swift
import Foundation

struct EconomyDB: Codable, Equatable {
    var coinsByUid: [String: Int] = [:]
    var trophiesByUid: [String: Int] = [:]
    var ownedByUid: [String: Set<String>] = [:]
    var selectedByUid: [String: String] = [:]
    var lastGiftDayByUid: [String: String] = [:]
}

final class LocalEconomyStore {
    static let shared = LocalEconomyStore()
    private init() { ensureLoaded() }

    private let ud = UserDefaults.standard
    private let storageKey = "local.economy.v1"

    private var db: EconomyDB = .init()
    private var loaded = false

    private(set) var activeUID: String = "local"
    func setActive(uid: String?) {
        ensureLoaded()
        activeUID = uid ?? "local"
    }

    // MARK: - Load/Save API

    func loadCoins() -> Int {
        ensureLoaded()
        // 25 монет по умолчанию для новых пользователей
        return db.coinsByUid[activeUID] ?? 25
    }

    func save(coins: Int) {
        ensureLoaded()
        db.coinsByUid[activeUID] = max(0, coins)
        persist()
    }

    func loadTrophies() -> Int {
        ensureLoaded()
        // 10 кубков по умолчанию для новых пользователей
        return db.trophiesByUid[activeUID] ?? 10
    }

    func save(trophies: Int) {
        ensureLoaded()
        db.trophiesByUid[activeUID] = max(0, trophies)
        persist()
    }

    func loadOwnedOutfits() -> Set<String> {
        ensureLoaded()
        return db.ownedByUid[activeUID] ?? []
    }

    func save(ownedOutfits: Set<String>) {
        ensureLoaded()
        db.ownedByUid[activeUID] = ownedOutfits
        persist()
    }

    func loadSelectedOutfitId() -> String? {
        ensureLoaded()
        return db.selectedByUid[activeUID]
    }

    func save(selectedOutfitId: String) {
        ensureLoaded()
        db.selectedByUid[activeUID] = selectedOutfitId
        persist()
    }

    var lastGiftDayKey: String? {
        ensureLoaded()
        return db.lastGiftDayByUid[activeUID]
    }

    func save(lastGiftDayKey key: String) {
        ensureLoaded()
        db.lastGiftDayByUid[activeUID] = key
        persist()
    }

    // MARK: - Storage

    private func ensureLoaded() {
        guard !loaded else { return }
        loaded = true
        guard let data = ud.data(forKey: storageKey) else {
            db = .init()
            return
        }
        do {
            db = try JSONDecoder().decode(EconomyDB.self, from: data)
        } catch {
            db = .init()
            print("LocalEconomyStore decode error:", error)
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(db)
            ud.set(data, forKey: storageKey)
        } catch {
            print("LocalEconomyStore persist error:", error)
        }
    }
}
