import SwiftUI

struct MainTabView: View {
    let homeViewModel: HomeViewModel

    var body: some View {
        TabView {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("Главная", systemImage: "house")
                }
            StatsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar")
                }
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.circle")
                }
        }
    }
}
