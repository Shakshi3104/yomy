import SwiftUI

struct FeaturedArticleCard: View {
    let article: Article

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(maxWidth: .infinity, minHeight: 220)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
