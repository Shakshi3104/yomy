import SwiftUI
import SwiftData

struct FeedDetailView: View {
    let feed: Feed
    @Environment(\.modelContext) private var context

    @State private var isRefreshing = false

    private var sortedArticles: [Article] {
        feed.articles.sorted { $0.publishedAt > $1.publishedAt }
    }

    var body: some View {
        List(sortedArticles) { article in
            NavigationLink(value: article) {
                ArticleRowView(article: article, showFeedName: false)
            }
            .contextMenu { ArticleContextMenu(article: article) }
        }
        .navigationTitle(feed.title.isEmpty ? feed.url : feed.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Article.self) { article in
            ArticleWebView(article: article)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        try? FeedService.shared.markAllRead(feed: feed, context: context)
                    } label: {
                        Label("Mark All Read", systemImage: "checkmark.circle")
                    }
                    Button {
                        Task { try? await FeedService.shared.refresh(feed: feed, context: context) }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            try? await FeedService.shared.refresh(feed: feed, context: context)
        }
        .overlay {
            if sortedArticles.isEmpty {
                ContentUnavailableView("No Articles", systemImage: "doc.text")
            }
        }
    }
}
