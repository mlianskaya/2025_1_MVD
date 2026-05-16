import Foundation
import FirebaseFirestore

struct GoalTransaction: Identifiable, Codable, Equatable {
    @DocumentID var id: String?

    var type: String
    var amount: Int

    var note: String?
    var challengeId: String?

    @ServerTimestamp var createdAt: Timestamp?

    init(
        id: String? = nil,
        type: String,
        amount: Int,
        note: String? = nil,
        challengeId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.note = note
        self.challengeId = challengeId
    }
}
