import Foundation

struct UserChallengeState: Codable, Equatable {
    let challengeId: String
    let startDate: Date
    var completedDayKeys: Set<String> // DayKey yyyy-MM-dd
}
