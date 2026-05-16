import Foundation
import FirebaseAuth
import FirebaseFirestore

enum GoalsRepoError: Error, LocalizedError {
    case notSignedIn
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Пользователь не авторизован"
        case .invalidAmount:
            return "Некорректная сумма"
        }
    }
}

final class GoalsRepository {
    private let db = Firestore.firestore()

    private var uid: String? { Auth.auth().currentUser?.uid }

    func createGoal(_ goal: Goal, setAsActive: Bool = true) async throws -> String {
        guard let uid else { throw GoalsRepoError.notSignedIn }

        let docRef = FirestorePaths.goals(uid: uid).document()
        var newGoal = goal
        newGoal.id = docRef.documentID

        try docRef.setData(from: newGoal, merge: true)

        if setAsActive {
            try await FirestorePaths.userDoc(uid: uid).setData([
                "activeGoalId": docRef.documentID,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        }

        return docRef.documentID
    }

    func fetchActiveGoal() async throws -> Goal? {
        guard let uid else { throw GoalsRepoError.notSignedIn }

        let userSnap = try await FirestorePaths.userDoc(uid: uid).getDocument()
        let activeGoalId = userSnap.data()?["activeGoalId"] as? String
        guard let goalId = activeGoalId else { return nil }

        let goalSnap = try await FirestorePaths.goal(uid: uid, goalId: goalId).getDocument()
        return try goalSnap.data(as: Goal.self)
    }

    func addTransaction(
        goalId: String,
        type: String,
        amount: Int,
        note: String? = nil,
        challengeId: String? = nil
    ) async throws {
        guard let uid else { throw GoalsRepoError.notSignedIn }
        guard amount > 0 else { throw GoalsRepoError.invalidAmount }

        let goalRef = FirestorePaths.goal(uid: uid, goalId: goalId)
        let txRef = FirestorePaths.transactions(uid: uid, goalId: goalId).document()

        try await db.runTransaction { transaction, errorPointer in
            do {
                let snap = try transaction.getDocument(goalRef)
                let raw = snap.data()?["currentAmount"]

                let current: Int
                if let v = raw as? Int { current = v }
                else if let v = raw as? Int64 { current = Int(v) }
                else if let v = raw as? NSNumber { current = v.intValue }
                else { current = 0 }

                let delta: Int
                switch type {
                case "deposit":
                    delta = amount
                case "withdraw":
                    delta = -amount
                case "correction":
                    delta = amount
                default:
                    delta = amount
                }

                transaction.setData([
                    "type": type,
                    "amount": amount,
                    "note": note as Any,
                    "challengeId": challengeId as Any,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: txRef, merge: true)

                transaction.updateData([
                    "currentAmount": current + delta,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: goalRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func fetchActiveGoalId() async throws -> String? {
        let goal = try await fetchActiveGoal()
        return goal?.id
    }

    /// Депозиты с `createdAt >= startDate` (только `type == deposit`, положительные суммы).
    func fetchDepositsSince(goalId: String, startDate: Date) async throws -> [(date: Date, amount: Int)] {
        guard let uid else { throw GoalsRepoError.notSignedIn }

        let snapshot = try await FirestorePaths.transactions(uid: uid, goalId: goalId)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .order(by: "createdAt", descending: false)
            .getDocuments()

        var result: [(date: Date, amount: Int)] = []
        result.reserveCapacity(snapshot.documents.count)

        for doc in snapshot.documents {
            let data = doc.data()
            guard (data["type"] as? String) == "deposit" else { continue }

            let amount: Int
            if let v = data["amount"] as? Int {
                amount = v
            } else if let v = data["amount"] as? Int64 {
                amount = Int(v)
            } else if let v = data["amount"] as? NSNumber {
                amount = v.intValue
            } else {
                continue
            }
            guard amount > 0, let ts = data["createdAt"] as? Timestamp else { continue }

            result.append((ts.dateValue(), amount))
        }

        return result
    }
}
