import Foundation

final class AppActivityService {
    private let store = AppActivityStore.shared

    func markAppOpen() {
        guard let uid = LocalUserStore.shared.activeUID else { return }

        Task {
            await store.markAppOpen(uid: uid)
        }
    }
}
