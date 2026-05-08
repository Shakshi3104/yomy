import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LatestView()
                .tabItem {
                    Label("最新", systemImage: "newspaper")
                }

            FeedsView()
                .tabItem {
                    Label("フィード", systemImage: "list.bullet")
                }

            SavedView()
                .tabItem {
                    Label("保存済み", systemImage: "bookmark")
                }

            SearchView()
                .tabItem {
                    Label("検索", systemImage: "magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}
