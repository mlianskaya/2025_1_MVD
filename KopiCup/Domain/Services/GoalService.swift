//
//  GoalService.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI

protocol GoalService {
    func observeGoal(_ handler: @escaping (Goal?) -> Void)
    func createGoal(_ goal: Goal)
    func updateGoal(_ goal: Goal)
    func deleteGoal()
    func addMoney(_ amount: Int)
    func addMoney(_ amount: Int, forDayIndex dayIndex: Int)
    
    func observeSeries(_ handler: @escaping (Series) -> Void)
    func updateSeries(_ series: Series)
}
