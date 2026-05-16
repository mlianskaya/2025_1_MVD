import FirebaseFirestore

enum FirestorePaths {
    static func userDoc(uid: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    static func goals(uid: String) -> CollectionReference {
        userDoc(uid: uid).collection("goals")
    }

    static func goal(uid: String, goalId: String) -> DocumentReference {
        goals(uid: uid).document(goalId)
    }

    static func transactions(uid: String, goalId: String) -> CollectionReference {
        goal(uid: uid, goalId: goalId).collection("transactions")
    }

    static func challengesCatalog() -> CollectionReference {
        Firestore.firestore().collection("challenges")
    }

    static func challengeState(uid: String) -> CollectionReference {
        userDoc(uid: uid).collection("challenge_state")
    }

    static func activeChallengeState(uid: String) -> DocumentReference {
        challengeState(uid: uid).document("active")
    }
}
