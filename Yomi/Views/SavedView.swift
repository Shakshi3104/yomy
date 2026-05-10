import SwiftUI
import SwiftData

struct SavedView: View {
    @Query(
        filter: #Predicate<Article> { $0.isSaved },
        sort: \Article.publishedAt,
        order: .reverse
    ) private var articles: [Article]

    @Environment(\.modelContext) private var context
    @State private var showSettings = false

    private var grouped: [(String, [Article])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"
        let groups = Dictionary(grouping: articles) { article in
            formatter.string(from: article.publishedAt)
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { month, monthArticles in
                    Section(month) {
                        ForEach(monthArticles) { article in
                            NavigationLink(value: article) {
                                ArticleRowView(article: article)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    article.isSaved = false
                                    try? context.save()
                                } label: {
                                    Label("Unsave", systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: Article.self) { article in
                ArticleWebView(article: article)
            }
            .overlay {
                if articles.isEmpty {
                    ContentUnavailableView(
                        "No Saved Articles",
                        systemImage: "bookmark",
                        description: Text("Long-press an article and tap Save for Later")
                    )
                }
            }
        }
    }
}
