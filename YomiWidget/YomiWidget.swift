import WidgetKit
import SwiftUI

struct ArticleEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ArticleEntry {
        ArticleEntry(date: .now, articles: [
            WidgetArticle(id: "1", title: "Sample article title displayed here", feedTitle: "Tech News", url: "", publishedAt: .now),
            WidgetArticle(id: "2", title: "Another sample article title", feedTitle: "World", url: "", publishedAt: .now.addingTimeInterval(-3600)),
            WidgetArticle(id: "3", title: "Third sample article", feedTitle: "Science", url: "", publishedAt: .now.addingTimeInterval(-7200)),
            WidgetArticle(id: "4", title: "Following the latest technology trends", feedTitle: "Tech News", url: "", publishedAt: .now.addingTimeInterval(-10800)),
            WidgetArticle(id: "5", title: "New design trends", feedTitle: "Design", url: "", publishedAt: .now.addingTimeInterval(-14400)),
            WidgetArticle(id: "6", title: "Best practices for dev tools", feedTitle: "Dev Tools", url: "", publishedAt: .now.addingTimeInterval(-18000)),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ArticleEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            let articles = WidgetDataStore.load()
            completion(ArticleEntry(date: .now, articles: articles.isEmpty ? placeholder(in: context).articles : articles))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArticleEntry>) -> Void) {
        let articles = WidgetDataStore.load()
        let entry: ArticleEntry
        if articles.isEmpty {
            entry = placeholder(in: context)
        } else {
            entry = ArticleEntry(date: .now, articles: articles)
        }
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Helpers

private func articleURL(_ webURL: String) -> URL {
    var components = URLComponents()
    components.scheme = "yomi"
    components.host = "open"
    components.queryItems = [URLQueryItem(name: "url", value: webURL)]
    return components.url ?? URL(string: "yomi://")!
}

// MARK: - Views

struct YomiSmallView: View {
    let entry: ArticleEntry

    var body: some View {
        if let article = entry.articles.first {
            VStack(alignment: .leading, spacing: 2) {
                Text(article.feedTitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)

                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .widgetURL(articleURL(article.url))
            .containerBackground(for: .widget) {
                ZStack {
                    if let uiImage = WidgetDataStore.loadImage(for: article.id) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color(.systemGray3), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.35),
                            .init(color: .black.opacity(0.55), location: 0.6),
                            .init(color: .black.opacity(0.9), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("No articles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

struct YomiMediumView: View {
    let entry: ArticleEntry

    var body: some View {
        Group {
            if entry.articles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "newspaper")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No articles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(entry.articles.prefix(3)) { article in
                        Link(destination: articleURL(article.url)) {
                            HStack(alignment: .center, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(article.feedTitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(article.title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)
                                }
                                Spacer(minLength: 4)
                                if let uiImage = WidgetDataStore.loadImage(for: article.id) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }

                        if article.id != entry.articles.prefix(3).last?.id {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct YomiLargeView: View {
    let entry: ArticleEntry

    var body: some View {
        Group {
            if entry.articles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "newspaper")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No articles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(entry.articles.prefix(6)) { article in
                        Link(destination: articleURL(article.url)) {
                            HStack(alignment: .center, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(article.feedTitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(article.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)
                                }
                                Spacer(minLength: 4)
                                if let uiImage = WidgetDataStore.loadImage(for: article.id) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 42)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                        }

                        if article.id != entry.articles.prefix(6).last?.id {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct YomiWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ArticleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            YomiSmallView(entry: entry)
        case .systemMedium:
            YomiMediumView(entry: entry)
        case .systemLarge:
            YomiLargeView(entry: entry)
        default:
            YomiSmallView(entry: entry)
        }
    }
}

// MARK: - Widget

struct YomiWidget: Widget {
    let kind = "YomiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YomiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("yomy")
        .description("Check the latest articles on your home screen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    YomiWidget()
} timeline: {
    ArticleEntry(date: .now, articles: [
        WidgetArticle(id: "1", title: "What's New in SwiftUI 2025", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-1800)),
    ])
}

#Preview(as: .systemMedium) {
    YomiWidget()
} timeline: {
    ArticleEntry(date: .now, articles: [
        WidgetArticle(id: "1", title: "What's New in SwiftUI 2025", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-1800)),
        WidgetArticle(id: "2", title: "Apple announces a new framework", feedTitle: "Tech News", url: "", publishedAt: .now.addingTimeInterval(-3600)),
        WidgetArticle(id: "3", title: "ML frontier: large model trends", feedTitle: "AI Journal", url: "", publishedAt: .now.addingTimeInterval(-7200)),
    ])
}

#Preview(as: .systemLarge) {
    YomiWidget()
} timeline: {
    ArticleEntry(date: .now, articles: [
        WidgetArticle(id: "1", title: "What's New in SwiftUI 2025", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-1800)),
        WidgetArticle(id: "2", title: "Apple announces a new framework", feedTitle: "Tech News", url: "", publishedAt: .now.addingTimeInterval(-3600)),
        WidgetArticle(id: "3", title: "ML frontier: large model trends", feedTitle: "AI Journal", url: "", publishedAt: .now.addingTimeInterval(-7200)),
        WidgetArticle(id: "4", title: "The complete guide to Swift 6 concurrency", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-10800)),
        WidgetArticle(id: "5", title: "New UX design trends in iOS 19", feedTitle: "Design Weekly", url: "", publishedAt: .now.addingTimeInterval(-14400)),
        WidgetArticle(id: "6", title: "Server-side Swift: present and future", feedTitle: "Backend News", url: "", publishedAt: .now.addingTimeInterval(-18000)),
    ])
}
