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
                article.isSaved ? "保存を解除" : "後で読む",
                systemImage: article.isSaved ? "bookmark.slash" : "bookmark"
            )
        }

        Button {
            article.isRead.toggle()
            try? context.save()
        } label: {
            Label(
                article.isRead ? "未読にする" : "既読にする",
                systemImage: article.isRead ? "envelope.badge" : "checkmark"
            )
        }

        Divider()

        ShareLink(item: URL(string: article.url)!) {
            Label("共有", systemImage: "square.and.arrow.up")
        }
    }
}
