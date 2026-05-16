import Foundation
import FirebaseFirestore

protocol PiggyProfileService {
    func fetchProfile(uid: String) async throws -> PiggyProfileDTO
    func createProfileIfNeeded(uid: String) async throws
    func saveProfile(uid: String, profile: PiggyProfileDTO) async throws
}

final class FirebasePiggyProfileService: PiggyProfileService {
    private let db = Firestore.firestore()

    private func profileRef(uid: String) -> DocumentReference {
        db.collection("users")
            .document(uid)
            .collection("Piggy")
            .document("profile")
    }

    func fetchProfile(uid: String) async throws -> PiggyProfileDTO {
        let snapshot = try await profileRef(uid: uid).getDocument()

        if let profile = try? snapshot.data(as: PiggyProfileDTO.self) {
            return normalized(profile)
        }

        let defaultProfile = PiggyProfileDTO.default
        try await saveProfile(uid: uid, profile: defaultProfile)
        return defaultProfile
    }

    func createProfileIfNeeded(uid: String) async throws {
        let ref = profileRef(uid: uid)
        let snapshot = try await ref.getDocument()

        guard !snapshot.exists else { return }

        try ref.setData(from: PiggyProfileDTO.default, merge: true)
    }

    func saveProfile(uid: String, profile: PiggyProfileDTO) async throws {
        try profileRef(uid: uid).setData(from: normalized(profile), merge: true)
    }

    private func normalized(_ profile: PiggyProfileDTO) -> PiggyProfileDTO {
        let owned = Array(Set(profile.ownedOutfitIds + ["piggy_cool"])).sorted()

        let selected: String
        if owned.contains(profile.selectedOutfitId) {
            selected = profile.selectedOutfitId
        } else {
            selected = "piggy_cool"
        }

        return PiggyProfileDTO(
            coins: max(0, profile.coins),
            trophies: max(0, profile.trophies),
            lastGiftDayKey: profile.lastGiftDayKey,
            ownedOutfitIds: owned,
            selectedOutfitId: selected
        )
    }
}
