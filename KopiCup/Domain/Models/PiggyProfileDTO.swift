import Foundation

struct PiggyProfileDTO: Codable {
    var coins: Int
    var trophies: Int
    var lastGiftDayKey: String?
    var ownedOutfitIds: [String]
    var selectedOutfitId: String

    static let `default` = PiggyProfileDTO(
        coins: 0,
        trophies: 0,
        lastGiftDayKey: nil,
        ownedOutfitIds: ["piggy_cool"],
        selectedOutfitId: "piggy_cool"
    )
}
