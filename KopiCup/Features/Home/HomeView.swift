import SwiftUI

enum HomeModal: Identifiable {
    case addGoal
    case goalDetails
    case editGoal
    case challengeDetails

    var id: String { String(describing: self) }
}

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var activeModal: HomeModal?
    @State private var goalSnapshot: Goal?

    @State private var showChallengeDetails: Bool = false
    @State private var showPigModal: Bool = false

    @EnvironmentObject private var economy: EconomyStore

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isGoalDetailsPresented: Binding<Bool> {
        Binding(
            get: { activeModal == .goalDetails },
            set: { newValue in
                if !newValue { activeModal = nil }
            }
        )
    }

    private var nonGoalDetailsModal: Binding<HomeModal?> {
        Binding(
            get: { activeModal == .goalDetails ? nil : activeModal },
            set: { activeModal = $0 }
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                topEconomyBar
                    .padding(.horizontal, 0)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .center, spacing: 12) {
                                Button {
                                    showPigModal = true
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 102/255, green: 190/255, blue: 0))
                                            .frame(width: 60, height: 60)

                                        Image(economy.selectedOutfitImageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 70, height: 80)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Открыть копилку")

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Привет, \(viewModel.userName)!")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 102/255, green: 190/255, blue: 0))

                                    Text("Продолжай в том же духе!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            if let goal = viewModel.goalVM.currentGoal {
                                GoalCardView(goal: goal)
                                    .onTapGesture {
                                        goalSnapshot = goal
                                        activeModal = .goalDetails
                                    }
                            } else {
                                EmptyGoalCardView {
                                    activeModal = .addGoal
                                }
                            }

                            if let seriesVM = viewModel.seriesVM {
                                SeriesCardView(viewModel: seriesVM)
                            }

                            if viewModel.challengeVM.displayedChallenge != nil {
                                ChallengeCardView(
                                    viewModel: viewModel.challengeVM,
                                    onAccept: { showChallengeDetails = true },
                                    onTrackToday: { showChallengeDetails = true }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            // Модалка по кнопке со свиньёй
            .sheet(isPresented: $showPigModal) {
                PiggyModalView(isPresented: $showPigModal)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(item: nonGoalDetailsModal) { modal in
                switch modal {
                case .addGoal:
                    GoalFormView(
                        isPresented: .constant(true),
                        onSave: { viewModel.goalVM.createGoal($0) }
                    )

                case .editGoal:
                    Group {
                        if let goal = viewModel.goalVM.currentGoal {
                            EditGoalView(
                                isPresented: .constant(true),
                                goal: goal,
                                onSave: { viewModel.goalVM.updateGoal($0) },
                                onDelete: { viewModel.goalVM.deleteGoal() }
                            )
                        } else {
                            EmptyView()
                        }
                    }

                case .challengeDetails:
                    ChallengeDetailView(
                        isPresented: .constant(true),
                        viewModel: viewModel.challengeVM
                    )

                case .goalDetails:
                    EmptyView()
                }
            }
            .sheet(isPresented: $showChallengeDetails) {
                ChallengeDetailView(
                    isPresented: $showChallengeDetails,
                    viewModel: viewModel.challengeVM
                )
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: isGoalDetailsPresented) {
                ZStack {
                    Color(UIColor.systemBackground).ignoresSafeArea()

                    Group {
                        if let goal = goalSnapshot {
                            if let seriesVM = viewModel.seriesVM {
                                AboutGoalView(
                                    goal: goal,
                                    onClose: {
                                        goalSnapshot = nil
                                        activeModal = nil
                                    },
                                    seriesVM: seriesVM,
                                    onAddMoney: {
                                        let goalToUse = goal
                                        goalSnapshot = nil
                                        activeModal = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            seriesVM.goal = goalToUse
                                            seriesVM.selectedDayIndex = seriesVM.currentDayIndex
                                            seriesVM.showAddMoneyModal = true
                                        }
                                    },
                                    onEdit: {
                                        goalSnapshot = nil
                                        activeModal = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            activeModal = .editGoal
                                        }
                                    }
                                )
                            } else {
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text("Готовим стрик…").foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        } else {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Загружаем цель…").foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .interactiveDismissDisabled(false)
                .presentationDetents([.large])
                .modifier(PresentationCornerRadiusCompat(16))
                .onDisappear { goalSnapshot = nil }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .alert("Челлендж провален", isPresented: Binding(
            get: { viewModel.challengeVM.showFailedChallengeAlert },
            set: { viewModel.challengeVM.showFailedChallengeAlert = $0 }
        )) {
            Button("Попробую снова!", role: .cancel) { }
        } message: {
            Text("Ты пропустил день в челлендже «\(viewModel.challengeVM.failedChallengeName)». Не расстраивайся — каждый новый день это шанс начать заново!")
        }
    }

    private var topEconomyBar: some View {
        HStack(spacing: 12) {
            counterChip(systemName: "dollarsign.circle.fill", value: economy.coins)
            counterChip(systemName: "trophy.fill", value: economy.trophies)

            Spacer()

            Button {
                Task {
                    let _ = await economy.collectDailyGift()
                }
            } label: {
                Image(systemName: "gift.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(economy.isGiftAvailableToday ? 0.2 : 0.1))
                    )
            }
            .disabled(!economy.isGiftAvailableToday)
            .buttonStyle(.plain)
            .accessibilityLabel("Ежедневный подарок")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(red: 102/255, green: 190/255, blue: 0)
                .ignoresSafeArea(edges: .horizontal)
        )
    }

    private func counterChip(systemName: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .foregroundColor(.white)

            Text("\(value)")
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }
}

private struct PresentationCornerRadiusCompat: ViewModifier {
    let radius: CGFloat

    init(_ radius: CGFloat) {
        self.radius = radius
    }

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}

private struct PresentationBackgroundClearCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(.clear)
        } else {
            content
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            viewModel: HomeViewModel(
                userService: MockUserService(),
                goalService: MockGoalService(),
                challengeService: MockChallengeService()
            )
        )
        .environmentObject(EconomyStore())
    }
}
