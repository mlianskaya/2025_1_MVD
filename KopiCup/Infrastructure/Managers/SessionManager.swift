import Foundation
import FirebaseAuth

@MainActor
final class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false

    private var handle: AuthStateDidChangeListenerHandle?

    func start() {
        guard handle == nil else { return }
        handle = Auth.auth().addStateDidChangeListener { _, user in
            self.isLoggedIn = (user != nil)
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
