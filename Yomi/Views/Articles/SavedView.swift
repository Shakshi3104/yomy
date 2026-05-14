import SwiftUI
import SwiftData

struct SavedView: View {
    @Query(
        filter: #Predicate<Article> { $0.isSaved },
        sort: \Article.publishedAt,
        order: .reverse
    ) private var articles: [Article]

    @Environment(\.modelContext) private var context
    @State private var selectedArticle: Article?

    private var dedupedArticles: [Article] {
        FeedService.dedupByURL(articles)
    }

    private var siblingCountsByURL: [String: Int] {
        var counts: [String: Int] = [:]
        for article in articles where !article.url.isEmpty {
            counts[article.url, default: 0] += 1
        }
        return counts
    }

    private func additionalFeedCount(for article: Article) -> Int {
        guard !article.url.isEmpty else { return 0 }
        return max(0, (siblingCountsByURL[article.url] ?? 1) - 1)
    }

    private var grouped: [(String, [Article])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM"
        let groups = Dictionary(grouping: dedupedArticles) { article in
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
                            Button {
                                selectedArticle = article
                            } label: {
                                ArticleRowView(
                                    article: article,
                                    additionalFeedCount: additionalFeedCount(for: article)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu { ArticleContextMenu(article: article) }
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    FeedService.shared.setSaved(article: article, isSaved: false, context: context)
                                } label: {
                                    Label("Unsave", systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved")
            .sheet(item: $selectedArticle) { article in
                NavigationStack {
                    ArticleWebView(article: article)
                }
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
