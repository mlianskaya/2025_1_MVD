//
//  UserChallenge.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

struct UserChallenge: Equatable {
    let challenge: Challenge
    var startDate: Date
    var progress: [Bool]
    
    var currentDayIndex: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(max(days, 0), 6)
    }
    
    var isTodayCompleted: Bool {
        return currentDayIndex < 7 && progress[currentDayIndex]
    }
}

