import SwiftUI

struct ArticleContextMenu: View {
    let article: Article
    @Environment(\.modelContext) private var context

    var body: some View {
        Button {
            article.isSaved.toggle()
            try? context.save()
        } label: {
            Label(
                article.isSaved ? "Unsave" : "Save for Later",
                systemImage: article.isSaved ? "bookmark.slash" : "bookmark"
            )
        }

        Button {
            article.isRead.toggle()
            try? context.save()
        } label: {
            Label(
                article.isRead ? "Mark as Unread" : "Mark as Read",
                systemImage: article.isRead ? "envelope.badge" : "checkmark"
            )
        }

        Divider()

        ShareLink(item: URL(string: article.url)!) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
