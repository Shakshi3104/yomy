import SwiftUI

struct ArticleFeedSections: View {
    let articles: [Article]
    @Binding var selectedArticle: Article?

    private var dedupedArticles: [Article] {
        FeedService.dedupByURL(articles)
    }

    private var siblingCountsByURL: [String: Int] {
        var counts: [String: Int] = [:]
        for article in articles where !article.url.isEmpty {
            counts[article.url, default: 0] += 1
        }
        return counts
    }

    private func additionalFeedCount(for article: Article) -> Int {
        guard !article.url.isEmpty else { return 0 }
        return max(0, (siblingCountsByURL[article.url] ?? 1) - 1)
    }

    private var featuredArticle: Article? {
        dedupedArticles.first
    }

    private var groupedArticles: [(String, [Article])] {
        let deduped = dedupedArticles
        let rest = featuredArticle != nil ? Array(deduped.dropFirst()) : deduped
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "MM/dd"
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "yyyy/MM/dd"
        let groups = Dictionary(grouping: rest) { article -> String in
            if cal.isDateInToday(article.publishedAt) { return "Today" }
            if cal.isDateInYesterday(article.publishedAt) { return "Yesterday" }
            let year = cal.component(.year, from: article.publishedAt)
            return year == currentYear
                ? shortFormatter.string(from: article.publishedAt)
                : fullFormatter.string(from: article.publishedAt)
        }
        let order = ["Today", "Yesterday"]
        return groups.sorted { a, b in
            let ia = order.firstIndex(of: a.key) ?? Int.max
            let ib = order.firstIndex(of: b.key) ?? Int.max
            if ia != ib { return ia < ib }
            let dateA = a.value.first?.publishedAt ?? .distantPast
            let dateB = b.value.first?.publishedAt ?? .distantPast
            return dateA > dateB
        }
    }

    var body: some View {
        Group {
            if let featured = featuredArticle {
                Section {
                    articleCardRow(article: featured, featured: true)
                }
            }

            ForEach(groupedArticles, id: \.0) { section, sectionArticles in
                Section(section) {
                    ForEach(sectionArticles) { article in
                        articleCardRow(article: article, featured: false)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func articleCardRow(article: Article, featured: Bool) -> some View {
        Button {
            selectedArticle = article
        } label: {
            ArticleRowView(
                article: article,
                featured: featured,
                additionalFeedCount: additionalFeedCount(for: article)
            )
        }
        .buttonStyle(.plain)
        .contextMenu { ArticleContextMenu(article: article) }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
