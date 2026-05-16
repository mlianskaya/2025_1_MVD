import SwiftUI
import FirebaseAuth

struct Outfit: Identifiable, Equatable, Codable {
    let id: String
    let imageName: String
    let price: Price

    enum Price: Codable, Equatable {
        case free
        case coins(Int)
        case trophies(Int)
    }
}

@MainActor
final class EconomyStore: ObservableObject {
    @Published private(set) var coins: Int = 0
    @Published private(set) var trophies: Int = 0
    @Published private(set) var lastGiftDayKey: String?

    @Published private(set) var ownedOutfitIds: Set<String> = []
    @Published private(set) var selectedOutfitId: String = "piggy_cool"

    let catalog: [Outfit] = [
        Outfit(id: "piggy_cool",      imageName: "piggy_cool",      price: .free),
        Outfit(id: "piggy_wizard",    imageName: "piggy_wizard",    price: .coins(20)),
        Outfit(id: "piggy_ballerina", imageName: "piggy_ballerina", price: .coins(30)),
        Outfit(id: "piggy_queen",     imageName: "piggy_queen",     price: .trophies(3))
    ]

    private let service: PiggyProfileService
    private var notificationToken: NSObjectProtocol?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init(service: PiggyProfileService = FirebasePiggyProfileService()) {
        self.service = service
        applyDefaultState()
        observeProfileChanges()
        observeAuthChanges()
    }

    deinit {
        if let notificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
        }

        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    var selectedOutfit: Outfit {
        catalog.first(where: { $0.id == selectedOutfitId }) ?? catalog[0]
    }

    var selectedOutfitImageName: String {
        selectedOutfit.imageName
    }

    var isGiftAvailableToday: Bool {
        let today = DayKey.make(from: Date())
        return lastGiftDayKey != today
    }

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    func bootstrapForCurrentUser() async {
        guard let uid = currentUid else {
            resetToDefaults()
            return
        }

        do {
            try await service.createProfileIfNeeded(uid: uid)
            let profile = try await service.fetchProfile(uid: uid)
            apply(profile: profile)
        } catch {
            print("EconomyStore bootstrap error:", error)
            resetToDefaults()
        }
    }

    func onActiveUserChanged() {
        Task {
            await bootstrapForCurrentUser()
        }
    }

    func setCoins(_ value: Int) async {
        coins = max(0, value)
        await persist()
    }

    func setTrophies(_ value: Int) async {
        trophies = max(0, value)
        await persist()
    }

    func canBuy(_ outfit: Outfit) -> Bool {
        guard !ownedOutfitIds.contains(outfit.id) else { return false }

        switch outfit.price {
        case .free:
            return true
        case .coins(let amount):
            return coins >= amount
        case .trophies(let amount):
            return trophies >= amount
        }
    }

    @discardableResult
    func buy(_ outfit: Outfit) async -> Bool {
        guard !ownedOutfitIds.contains(outfit.id) else { return true }

        switch outfit.price {
        case .free:
            ownedOutfitIds.insert(outfit.id)

        case .coins(let amount):
            guard coins >= amount else { return false }
            coins -= amount
            ownedOutfitIds.insert(outfit.id)

        case .trophies(let amount):
            guard trophies >= amount else { return false }
            trophies -= amount
            ownedOutfitIds.insert(outfit.id)
        }

        normalizeLocalState()
        await persist()
        return true
    }

    func select(_ outfit: Outfit) async {
        guard ownedOutfitIds.contains(outfit.id) else { return }
        guard catalog.contains(where: { $0.id == outfit.id }) else { return }

        selectedOutfitId = outfit.id
        await persist()
    }

    @discardableResult
    func collectDailyGift() async -> Bool {
        do {
            let didReceive = try await RewardService.shared.claimDailyGift()
            if didReceive {
                await bootstrapForCurrentUser()
            }
            return didReceive
        } catch {
            print("EconomyStore collectDailyGift error:", error)
            return false
        }
    }

    private func observeProfileChanges() {
        notificationToken = NotificationCenter.default.addObserver(
            forName: .piggyProfileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.bootstrapForCurrentUser()
            }
        }
    }

    private func observeAuthChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor in
                await self.bootstrapForCurrentUser()
            }
        }
    }

    private func persist() async {
        guard let uid = currentUid else { return }

        do {
            try await service.saveProfile(uid: uid, profile: makeDTO())
        } catch {
            print("EconomyStore persist error:", error)
        }
    }

    private func makeDTO() -> PiggyProfileDTO {
        PiggyProfileDTO(
            coins: max(0, coins),
            trophies: max(0, trophies),
            lastGiftDayKey: lastGiftDayKey,
            ownedOutfitIds: Array(ownedOutfitIds).sorted(),
            selectedOutfitId: selectedOutfitId
        )
    }

    private func apply(profile: PiggyProfileDTO) {
        coins = max(0, profile.coins)
        trophies = max(0, profile.trophies)
        lastGiftDayKey = profile.lastGiftDayKey
        ownedOutfitIds = Set(profile.ownedOutfitIds)
        selectedOutfitId = profile.selectedOutfitId

        normalizeLocalState()
    }

    private func normalizeLocalState() {
        ownedOutfitIds.insert("piggy_cool")

        if !catalog.contains(where: { $0.id == selectedOutfitId }) {
            selectedOutfitId = "piggy_cool"
        }

        if !ownedOutfitIds.contains(selectedOutfitId) {
            selectedOutfitId = "piggy_cool"
        }

        coins = max(0, coins)
        trophies = max(0, trophies)
    }

    private func resetToDefaults() {
        applyDefaultState()
    }

    private func applyDefaultState() {
        coins = 0
        trophies = 0
        lastGiftDayKey = nil
        ownedOutfitIds = ["piggy_cool"]
        selectedOutfitId = "piggy_cool"
    }
}
