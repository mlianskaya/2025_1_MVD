import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var userStorage: UserStorage
    @StateObject private var rewardBannerCenter = RewardBannerCenter()
    @AppStorage("settings.theme.darkMode") private var isDarkMode: Bool = false

    private let userService: UserService = LocalUserService()
    private let goalService = FirebaseGoalService()
    private let challengeService: ChallengeService = FirebaseChallengeService()
    private let appActivityService = AppActivityService()

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if userStorage.isLoggedIn {
                    MainTabView(
                        homeViewModel: HomeViewModel(
                            userService: userService,
                            goalService: goalService,
                            challengeService: challengeService
                        )
                    )
                    .onAppear {
                        appActivityService.markAppOpen()
                    }
                } else {
                    NavigationStack {
                        AuthView(onAuthSuccess: {})
                    }
                }
            }

            if let banner = rewardBannerCenter.currentBanner {
                RewardToastView(data: banner)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .zIndex(999)
                    .allowsHitTesting(false)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
