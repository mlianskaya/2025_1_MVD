//
//  HomeViewModel.swift
//  KopiCup
//
//  Created by Павел Гордиенко on 12/23/25.
//

import SwiftUI
import Combine
import FirebaseAuth

final class HomeViewModel: ObservableObject {
    @Published var userName: String = ""

    var goalVM: GoalViewModel
    @Published var seriesVM: SeriesViewModel?
    var challengeVM: ChallengeViewModel

    private let userService: UserService
    private let goalService: GoalService

    private var cancellables = Set<AnyCancellable>()
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var seriesChangesCancellable: AnyCancellable?

    init(userService: UserService, goalService: GoalService, challengeService: ChallengeService) {
        self.userService = userService
        self.goalService = goalService

        self.goalVM = GoalViewModel(goalService: goalService)
        self.challengeVM = ChallengeViewModel(challengeService: challengeService)
        self.seriesVM = nil

        goalVM.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        challengeVM.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        goalVM.$currentGoal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goal in
                guard let self else { return }
                self.seriesVM?.goal = goal
            }
            .store(in: &cancellables)

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            if let uid = user?.uid {
                let vm = SeriesViewModel(goalService: self.goalService, uid: uid)

                vm.goal = self.goalVM.currentGoal

                self.seriesVM = vm
                self.bindSeriesVMChanges(vm)
            } else {
                self.seriesVM = nil
                self.seriesChangesCancellable = nil
            }
        }
    }

    private func bindSeriesVMChanges(_ vm: SeriesViewModel) {
        seriesChangesCancellable = vm.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    func loadData() {
        userService.fetchUser { [weak self] user in
            DispatchQueue.main.async { self?.userName = user.name }
        }
    }
}
