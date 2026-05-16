import SwiftUI
import Combine

@MainActor
final class RewardBannerCenter: ObservableObject {
    @Published var currentBanner: RewardToastData?

    private var hideTask: Task<Void, Never>?
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default
            .publisher(for: .rewardDidApply)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard
                    let self,
                    let userInfo = notification.userInfo,
                    let title = userInfo[RewardNotificationUserInfoKeys.title] as? String,
                    let message = userInfo[RewardNotificationUserInfoKeys.message] as? String
                else {
                    return
                }

                self.show(title: title, message: message)
            }
    }

    func show(title: String, message: String) {
        hideTask?.cancel()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            currentBanner = RewardToastData(title: title, message: message)
        }

        hideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                guard let self else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    self.currentBanner = nil
                }
            }
        }
    }
}
