import Foundation
import FirebaseAuth

final class UserStorage: ObservableObject {

    @Published var name: String = "Гость"
    @Published var registrationDate: Date? = nil
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var uid: String? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        observeAuthState()
    }

    private func observeAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            self.uid = user?.uid
            self.isLoggedIn = (user != nil)
            self.registrationDate = user?.metadata.creationDate

            let local = LocalUserService()
            local.setActive(uid: user?.uid)
            LocalChallengeStore.shared.setActive(uid: user?.uid)

            if user != nil {
                let profile = local.fetchProfile()
                self.name = profile.name
            } else {
                self.name = "Гость"
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out error:", error)
        }

        let local = LocalUserService()
        local.setActive(uid: nil)

        LocalChallengeStore.shared.setActive(uid: nil)

        name = "Гость"
        registrationDate = nil
        uid = nil
        isLoggedIn = false
    }

    func loginSucceeded() {
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
