//
//  MockChallengeService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI
import Combine

class MockChallengeService: ChallengeService {
    @Published var userChallenge: UserChallenge?
    
    func loadChallenges(completion: @escaping ([Challenge]) -> Void) {
        completion([
            Challenge(id: "1", name: "Не покупать кофе", description: "Попробуй день без кофе", difficulty: 1),
            Challenge(id: "2", name: "Прогулка 5км", description: "Ходи пешком", difficulty: 2),
            Challenge(id: "3", name: "Без сахара", description: "Никаких сладостей", difficulty: 3)
        ])
    }
    
    func observeUserChallenge(_ handler: @escaping (UserChallenge?) -> Void) {
        $userChallenge.sink(receiveValue: handler).store(in: &cancellables)
    }
    
    func startChallenge(_ challenge: Challenge) {
        self.userChallenge = UserChallenge(challenge: challenge, startDate: Date(), progress: Array(repeating: false, count: 7))
    }
    
    func declineChallenge() { self.userChallenge = nil }
    
    func markDayComplete() {
        guard var uc = userChallenge else { return }
        if uc.currentDayIndex < 7 {
            uc.progress[uc.currentDayIndex] = true
            self.userChallenge = uc
        }
    }
    private var cancellables = Set<AnyCancellable>()
}
