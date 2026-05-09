import SwiftUI

struct ContentView: View {
    @State private var widgetURL: URL?

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
        .onOpenURL { url in
            guard url.scheme == "yomi",
                  url.host == "open",
                  let urlString = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "url" })?.value,
                  let articleURL = URL(string: urlString) else { return }
            widgetURL = articleURL
        }
        .sheet(isPresented: Binding(
            get: { widgetURL != nil },
            set: { if !$0 { widgetURL = nil } }
        )) {
            if let url = widgetURL {
                NavigationStack {
                    WebViewRepresentable(url: url)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") { widgetURL = nil }
                            }
                        }
                }
            }
        }
    }
}
