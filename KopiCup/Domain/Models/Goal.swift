import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift

struct Goal: Identifiable, Codable, Equatable {
    @DocumentID var id: String?

    var title: String
    var description: String

    var targetAmount: Int
    var currentAmount: Int

    var currency: String

    var status: String

    var deadlineDate: Date?
    var productLink: String?
    var imageURL: String?

    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?

    init(
        id: String? = nil,
        title: String,
        description: String,
        targetAmount: Int,
        currentAmount: Int = 0,
        currency: String,
        status: String = "active",
        deadlineDate: Date? = nil,
        productLink: String? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.currency = currency
        self.status = status
        self.deadlineDate = deadlineDate
        self.productLink = productLink
        self.imageURL = imageURL
    }
}

extension Goal {
    static let empty = Goal(
        id: nil,
        title: "",
        description: "",
        targetAmount: 0,
        currentAmount: 0,
        currency: "EUR",
        status: "active"
    )

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return Double(currentAmount) / Double(targetAmount)
    }
}
