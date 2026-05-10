import SwiftUI
import SwiftData

struct FeaturedArticleCard: View {
    let article: Article
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageLayer
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                if let feedTitle = article.feed?.title {
                    Text(feedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var imageLayer: some View {
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
}
