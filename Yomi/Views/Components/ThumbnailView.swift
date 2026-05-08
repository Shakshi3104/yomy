import SwiftUI
import SwiftData

// Article thumbnail that lazily fetches OG image when imageURL is nil.
struct ThumbnailView: View {
    let article: Article
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
            } else {
                Color(.systemGray5)
                    .task(id: article.url) {
                        guard !article.url.isEmpty else { return }
                        if let url = await OGImageFetcher.shared.fetch(articleURL: article.url) {
                            article.imageURL = url
                            try? context.save()
                        }
                    }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
