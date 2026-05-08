import SwiftUI
import SwiftData

struct FeaturedArticleCard: View {
    let article: Article
    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            imageLayer
            gradientLayer
            textLayer
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var imageLayer: some View {
        if let imageURL = article.imageURL, let url = URL(string: imageURL) {
            CachedAsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.systemGray5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var gradientLayer: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.75)],
            startPoint: .center,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var textLayer: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let feedTitle = article.feed?.title {
                Text(feedTitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text(article.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(3)
        }
        .padding(16)
    }
}
