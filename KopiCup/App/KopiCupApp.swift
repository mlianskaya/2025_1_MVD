import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        setupFirestore()
        return true
    }
    
    private func setupFirestore() {
        let db = Firestore.firestore()
        let settings = Firestore.firestore().settings
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
}

@main
struct KopiCupApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    @StateObject private var userStorage = UserStorage()
    @StateObject private var economy = EconomyStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(userStorage)
                .environmentObject(economy)
        }
    }
}
