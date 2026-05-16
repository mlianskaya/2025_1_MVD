//
//  UserChallengeViewModel.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

final class UserChallengeViewModel: ObservableObject {

    @Published private(set) var progress: [Bool]
    @Published private(set) var canCompleteToday: Bool

    init(progress: [Bool]) {
        self.progress = progress
        self.canCompleteToday = !progress.last.orFalse
    }

    func completeToday() {
        guard canCompleteToday else { return }
        if let index = progress.firstIndex(of: false) {
            progress[index] = true
        }
        canCompleteToday = false
    }

    func cancel() {
        progress = Array(repeating: false, count: progress.count)
        canCompleteToday = true
    }
}

