import SwiftUI

struct FeedRowView: View {
    let feed: Feed

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(feed.title.isEmpty ? feed.url : feed.title)
                    .font(.body)
                    .lineLimit(1)

                if !feed.category.isEmpty && feed.category != "General" {
                    Text(feed.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if feed.unreadCount > 0 {
                Text("\(feed.unreadCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor, in: Capsule())
            }
        }
    }
}
