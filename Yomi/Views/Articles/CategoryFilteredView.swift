import SwiftUI
import SwiftData

struct CategoryFilteredView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Article.publishedAt, order: .reverse) private var articles: [Article]
    @Query private var feeds: [Feed]

    let category: Category

    @State private var isRefreshing = false
    @State private var selectedArticle: Article?

    private var filteredArticles: [Article] {
        let name = category.name
        return articles.filter { ($0.feed?.category ?? "") == name }
    }

    var body: some View {
        List {
            ArticleFeedSections(
                articles: filteredArticles,
                showsFeatured: false,
                selectedArticle: $selectedArticle
            )
        }
        .navigationTitle(category.name)
        .sheet(item: $selectedArticle) { article in
            NavigationStack {
                ArticleWebView(article: article)
            }
        }
        .refreshable {
            await refresh()
        }
        .overlay {
            if filteredArticles.isEmpty && !isRefreshing {
                ContentUnavailableView(
                    "No Articles",
                    systemImage: "newspaper",
                    description: Text("No articles in \(category.name)")
                )
            }
        }
    }

    private func refresh() async {
        isRefreshing = true
        let categoryFeeds = feeds.filter { $0.category == category.name }
        await FeedService.shared.refreshAll(feeds: categoryFeeds, context: context)
        isRefreshing = false
    }
}
