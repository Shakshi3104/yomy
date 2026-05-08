import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var context
    @State private var query = ""

    var body: some View {
        NavigationStack {
            SearchResultsView(query: query)
                .navigationTitle("検索")
                .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "記事を検索")
        }
    }
}

private struct SearchResultsView: View {
    let query: String

    @Query private var articles: [Article]

    init(query: String) {
        self.query = query
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            _articles = Query(sort: \Article.publishedAt, order: .reverse)
        } else {
            _articles = Query(
                filter: #Predicate<Article> { article in
                    article.title.localizedStandardContains(trimmed) ||
                    article.summary.localizedStandardContains(trimmed)
                },
                sort: \Article.publishedAt,
                order: .reverse
            )
        }
    }

    var body: some View {
        List(articles) { article in
            NavigationLink(value: article) {
                ArticleRowView(article: article)
            }
            .simultaneousGesture(TapGesture().onEnded {
                article.isRead = true
            })
        }
        .navigationDestination(for: Article.self) { article in
            ArticleWebView(article: article)
        }
        .overlay {
            if articles.isEmpty && !query.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}
