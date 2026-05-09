import WidgetKit
import SwiftUI

struct ArticleEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ArticleEntry {
        ArticleEntry(date: .now, articles: [
            WidgetArticle(id: "1", title: "サンプル記事のタイトルがここに表示されます", feedTitle: "Tech News", url: "", publishedAt: .now),
            WidgetArticle(id: "2", title: "別のサンプル記事のタイトル", feedTitle: "World", url: "", publishedAt: .now.addingTimeInterval(-3600)),
            WidgetArticle(id: "3", title: "3つ目のサンプル記事", feedTitle: "Science", url: "", publishedAt: .now.addingTimeInterval(-7200)),
            WidgetArticle(id: "4", title: "最新テクノロジーの動向を追う", feedTitle: "Tech News", url: "", publishedAt: .now.addingTimeInterval(-10800)),
            WidgetArticle(id: "5", title: "デザインの新しいトレンド", feedTitle: "Design", url: "", publishedAt: .now.addingTimeInterval(-14400)),
            WidgetArticle(id: "6", title: "開発ツールのベストプラクティス", feedTitle: "Dev Tools", url: "", publishedAt: .now.addingTimeInterval(-18000)),
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "newspaper.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(article.feedTitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(4)

                Text(article.publishedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetURL(articleURL(article.url))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("記事なし")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct YomiMediumView: View {
    let entry: ArticleEntry

    var body: some View {
        if entry.articles.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("記事なし")
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
}

struct YomiLargeView: View {
    let entry: ArticleEntry

    var body: some View {
        if entry.articles.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text("記事なし")
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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("yomy")
        .description("最新の記事をホーム画面でチェック")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    YomiWidget()
} timeline: {
    ArticleEntry(date: .now, articles: [
        WidgetArticle(id: "1", title: "SwiftUI の新機能まとめ 2025", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-1800)),
    ])
}

#Preview(as: .systemMedium) {
    YomiWidget()
} timeline: {
    ArticleEntry(date: .now, articles: [
        WidgetArticle(id: "1", title: "SwiftUI の新機能まとめ 2025", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-1800)),
        WidgetArticle(id: "2", title: "Appleが新しいフレームワークを発表", feedTitle: "Tech News", url: "", publishedAt: .now.addingTimeInterval(-3600)),
        WidgetArticle(id: "3", title: "機械学習の最前線：大規模モデルの動向", feedTitle: "AI Journal", url: "", publishedAt: .now.addingTimeInterval(-7200)),
    ])
}

#Preview(as: .systemLarge) {
    YomiWidget()
} timeline: {
    ArticleEntry(date: .now, articles: [
        WidgetArticle(id: "1", title: "SwiftUI の新機能まとめ 2025", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-1800)),
        WidgetArticle(id: "2", title: "Appleが新しいフレームワークを発表", feedTitle: "Tech News", url: "", publishedAt: .now.addingTimeInterval(-3600)),
        WidgetArticle(id: "3", title: "機械学習の最前線：大規模モデルの動向", feedTitle: "AI Journal", url: "", publishedAt: .now.addingTimeInterval(-7200)),
        WidgetArticle(id: "4", title: "Swift 6の並行処理完全ガイド", feedTitle: "Swift Blog", url: "", publishedAt: .now.addingTimeInterval(-10800)),
        WidgetArticle(id: "5", title: "iOS 19で変わるUXデザインの新潮流", feedTitle: "Design Weekly", url: "", publishedAt: .now.addingTimeInterval(-14400)),
        WidgetArticle(id: "6", title: "サーバーサイドSwiftの現状と未来", feedTitle: "Backend News", url: "", publishedAt: .now.addingTimeInterval(-18000)),
    ])
}
