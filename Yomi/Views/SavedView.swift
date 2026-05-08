import SwiftUI
import SwiftData

struct SavedView: View {
    @Query(
        filter: #Predicate<Article> { $0.isSaved },
        sort: \Article.publishedAt,
        order: .reverse
    ) private var articles: [Article]

    @Environment(\.modelContext) private var context

    private var grouped: [(String, [Article])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
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
                                    Label("保存解除", systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("保存済み")
            .navigationDestination(for: Article.self) { article in
                ArticleWebView(article: article)
            }
            .overlay {
                if articles.isEmpty {
                    ContentUnavailableView(
                        "保存した記事はありません",
                        systemImage: "bookmark",
                        description: Text("記事を長押しして「後で読む」で保存できます")
                    )
                }
            }
        }
    }
}
