import SwiftUI
import SwiftData

struct FeedDetailView: View {
    let feed: Feed
    @Environment(\.modelContext) private var context

    @State private var isRefreshing = false
    @State private var selectedArticle: Article?

    private var sortedArticles: [Article] {
        feed.articles.sorted { $0.publishedAt > $1.publishedAt }
    }

    var body: some View {
        List(sortedArticles) { article in
            Button {
                selectedArticle = article
            } label: {
                ArticleRowView(article: article, showFeedName: false)
            }
            .buttonStyle(.plain)
            .contextMenu { ArticleContextMenu(article: article) }
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .navigationTitle(feed.title.isEmpty ? feed.url : feed.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedArticle) { article in
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
