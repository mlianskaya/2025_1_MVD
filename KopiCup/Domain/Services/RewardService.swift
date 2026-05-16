import Foundation
import FirebaseAuth
import FirebaseFirestore

final class RewardService {
    static let shared = RewardService()

    private let db = Firestore.firestore()

    private init() {}

    enum RewardError: Error, LocalizedError {
        case notSignedIn

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "Пользователь не авторизован"
            }
        }
    }

    enum RewardType: String {
        case dailyGift
        case goalCompleted
        case challengeCompleted
        case weeklyStreak
    }

    enum RewardValues {
        static let dailyGiftCoins = 3
        static let weeklyStreakTrophies = 1
        static let goalCompletedTrophies = 2

        static func challengeCoins(for difficulty: Int) -> Int {
            switch difficulty {
            case 3:
                return 12
            case 2:
                return 8
            default:
                return 5
            }
        }
    }

    private var currentUid: String? {
        Auth.auth().currentUser?.uid
    }

    private func profileRef(uid: String) -> DocumentReference {
        db.collection("users")
            .document(uid)
            .collection("Piggy")
            .document("profile")
    }

    private func claimRef(uid: String, claimId: String) -> DocumentReference {
        db.collection("users")
            .document(uid)
            .collection("PiggyRewardClaims")
            .document(claimId)
    }

    @discardableResult
    func claimDailyGift() async throws -> Bool {
        guard let uid = currentUid else { throw RewardError.notSignedIn }

        let todayKey = DayKey.make(from: Date())
        let claimId = "dailyGift_\(todayKey)"

        let didApply = try await applyRewardIfNeeded(
            uid: uid,
            claimId: claimId,
            type: .dailyGift,
            coinsDelta: RewardValues.dailyGiftCoins,
            trophiesDelta: 0,
            lastGiftDayKey: todayKey,
            meta: [
                "dayKey": todayKey
            ]
        )

        if didApply {
            await postRewardPopup(
                type: .dailyGift,
                title: "Ежедневный подарок",
                message: "+\(RewardValues.dailyGiftCoins) монеты"
            )
        }

        return didApply
    }

    @discardableResult
    func claimGoalCompleted(goalId: String) async throws -> Bool {
        guard let uid = currentUid else { throw RewardError.notSignedIn }

        let claimId = "goalCompleted_\(goalId)"

        let didApply = try await applyRewardIfNeeded(
            uid: uid,
            claimId: claimId,
            type: .goalCompleted,
            coinsDelta: 0,
            trophiesDelta: RewardValues.goalCompletedTrophies,
            lastGiftDayKey: nil,
            meta: [
                "goalId": goalId
            ]
        )

        if didApply {
            await postRewardPopup(
                type: .goalCompleted,
                title: "Цель закрыта",
                message: "+\(RewardValues.goalCompletedTrophies) трофея"
            )
        }

        return didApply
    }

    @discardableResult
    func claimWeeklyStreak(weekKey: String) async throws -> Bool {
        guard let uid = currentUid else { throw RewardError.notSignedIn }

        let claimId = "weeklyStreak_\(weekKey)"

        let didApply = try await applyRewardIfNeeded(
            uid: uid,
            claimId: claimId,
            type: .weeklyStreak,
            coinsDelta: 0,
            trophiesDelta: RewardValues.weeklyStreakTrophies,
            lastGiftDayKey: nil,
            meta: [
                "weekKey": weekKey
            ]
        )

        if didApply {
            await postRewardPopup(
                type: .weeklyStreak,
                title: "Недельный стрик сохранён",
                message: "+\(RewardValues.weeklyStreakTrophies) трофей"
            )
        }

        return didApply
    }

    @discardableResult
    func claimChallengeCompleted(
        challengeId: String,
        startDate: Date,
        difficulty: Int
    ) async throws -> Bool {
        guard let uid = currentUid else { throw RewardError.notSignedIn }

        let startKey = DayKey.make(from: startDate)
        let claimId = "challengeCompleted_\(challengeId)_\(startKey)"
        let coins = RewardValues.challengeCoins(for: difficulty)

        let didApply = try await applyRewardIfNeeded(
            uid: uid,
            claimId: claimId,
            type: .challengeCompleted,
            coinsDelta: coins,
            trophiesDelta: 0,
            lastGiftDayKey: nil,
            meta: [
                "challengeId": challengeId,
                "startDayKey": startKey,
                "difficulty": difficulty
            ]
        )

        if didApply {
            await postRewardPopup(
                type: .challengeCompleted,
                title: "Челлендж завершён",
                message: "+\(coins) монет"
            )
        }

        return didApply
    }

    @discardableResult
    private func applyRewardIfNeeded(
        uid: String,
        claimId: String,
        type: RewardType,
        coinsDelta: Int,
        trophiesDelta: Int,
        lastGiftDayKey: String?,
        meta: [String: Any]
    ) async throws -> Bool {
        let profileRef = profileRef(uid: uid)
        let rewardClaimRef = claimRef(uid: uid, claimId: claimId)

        let rawResult = try await db.runTransaction { transaction, errorPointer in
            do {
                let claimSnapshot = try transaction.getDocument(rewardClaimRef)
                if claimSnapshot.exists {
                    return false
                }

                let profileSnapshot = try transaction.getDocument(profileRef)
                let profileData = profileSnapshot.data() ?? [:]

                let currentCoins = Self.intValue(profileData["coins"])
                let currentTrophies = Self.intValue(profileData["trophies"])
                let currentOwnedOutfitIds = Self.stringArrayValue(profileData["ownedOutfitIds"], defaultValue: ["piggy_cool"])
                let currentSelectedOutfitId = Self.stringValue(profileData["selectedOutfitId"], defaultValue: "piggy_cool")
                let currentLastGiftDayKey = profileData["lastGiftDayKey"] as? String

                let normalizedOwned = Array(Set(currentOwnedOutfitIds + ["piggy_cool"])).sorted()
                let normalizedSelected = normalizedOwned.contains(currentSelectedOutfitId) ? currentSelectedOutfitId : "piggy_cool"

                var updatedProfile: [String: Any] = [
                    "coins": max(0, currentCoins + coinsDelta),
                    "trophies": max(0, currentTrophies + trophiesDelta),
                    "ownedOutfitIds": normalizedOwned,
                    "selectedOutfitId": normalizedSelected
                ]

                if let lastGiftDayKey {
                    updatedProfile["lastGiftDayKey"] = lastGiftDayKey
                } else if let currentLastGiftDayKey {
                    updatedProfile["lastGiftDayKey"] = currentLastGiftDayKey
                }

                transaction.setData(updatedProfile, forDocument: profileRef, merge: true)

                var claimData: [String: Any] = [
                    "type": type.rawValue,
                    "coinsDelta": coinsDelta,
                    "trophiesDelta": trophiesDelta,
                    "createdAt": FieldValue.serverTimestamp()
                ]

                for (key, value) in meta {
                    claimData[key] = value
                }

                transaction.setData(claimData, forDocument: rewardClaimRef, merge: false)

                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return false
            }
        }

        let didApply = (rawResult as? Bool) ?? false

        if didApply {
            await MainActor.run {
                NotificationCenter.default.post(name: .piggyProfileDidChange, object: nil)
            }
        }

        return didApply
    }

    @MainActor
    private func postRewardPopup(
        type: RewardType,
        title: String,
        message: String
    ) {
        NotificationCenter.default.post(
            name: .rewardDidApply,
            object: nil,
            userInfo: [
                RewardNotificationUserInfoKeys.type: type.rawValue,
                RewardNotificationUserInfoKeys.title: title,
                RewardNotificationUserInfoKeys.message: message
            ]
        )
    }

    private static func intValue(_ value: Any?) -> Int {
        switch value {
        case let intValue as Int:
            return intValue
        case let int64Value as Int64:
            return Int(int64Value)
        case let numberValue as NSNumber:
            return numberValue.intValue
        default:
            return 0
        }
    }

    private static func stringArrayValue(_ value: Any?, defaultValue: [String]) -> [String] {
        guard let array = value as? [String], !array.isEmpty else {
            return defaultValue
        }
        return array
    }

    private static func stringValue(_ value: Any?, defaultValue: String) -> String {
        guard let value = value as? String, !value.isEmpty else {
            return defaultValue
        }
        return value
    }
}

enum RewardNotificationUserInfoKeys {
    static let type = "type"
    static let title = "title"
    static let message = "message"
}

extension Notification.Name {
    static let piggyProfileDidChange = Notification.Name("piggyProfileDidChange")
    static let rewardDidApply = Notification.Name("rewardDidApply")
}
