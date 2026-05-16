import SwiftUI

struct SettingsView: View {
    @ObservedObject var userStorage = UserStorage()
    var body: some View {
        VStack() {
            Text("Настройки")
                .font(.title)
                .fontWeight(.bold)
            Button(role: .destructive) {
                do { try AuthManager.shared.signOut() }
                catch { print(error) }
            } label: {
                Text("Выйти")
            }
            .foregroundColor(.red)
            .padding()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
