import SwiftUI

struct ContentView: View {
    @State private var widgetURL: URL?

    var body: some View {
        tabs
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
                                    Button("Close") { widgetURL = nil }
                                }
                            }
                    }
                }
            }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 26.0, *) {
            TabView {
                Tab("Latest", systemImage: "newspaper") {
                    LatestView()
                }
                Tab("Feeds", systemImage: "list.bullet") {
                    FeedsView()
                }
                Tab("Saved", systemImage: "bookmark") {
                    SavedView()
                }
                Tab(role: .search) {
                    SearchView()
                }
            }
        } else {
            TabView {
                LatestView()
                    .tabItem {
                        Label("Latest", systemImage: "newspaper")
                    }

                FeedsView()
                    .tabItem {
                        Label("Feeds", systemImage: "list.bullet")
                    }

                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark")
                    }

                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
            }
        }
    }
}
