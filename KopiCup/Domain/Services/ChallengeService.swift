//
//  ChallengeService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

protocol ChallengeService {
    func loadChallenges(completion: @escaping ([Challenge]) -> Void)
    func observeUserChallenge(_ handler: @escaping (UserChallenge?) -> Void)
    func startChallenge(_ challenge: Challenge)
    func declineChallenge()
    func markDayComplete()
}

