import SwiftUI

struct ArticleFeedSections: View {
    let articles: [Article]
    var showsFeatured: Bool = true
    @Binding var selectedArticle: Article?

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f
    }()

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    private var siblingCountsByURL: [String: Int] {
        var counts: [String: Int] = [:]
        for article in articles where !article.url.isEmpty {
            counts[article.url, default: 0] += 1
        }
        return counts
    }

    private static func group(_ articles: [Article]) -> [(String, [Article])] {
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: Date())
        let groups = Dictionary(grouping: articles) { article -> String in
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
        // 派生データ(dedup・重複カウント・グルーピング)は body 評価ごとに 1 回だけ計算する。
        // 各行から siblingCountsByURL を呼ぶ・dedup を複数回走らせると
        // 行数×記事数の O(n²) となり、スクロール中の再評価で固まる原因になっていた。
        let deduped = FeedService.dedupByURL(articles)
        let counts = siblingCountsByURL
        let featured = showsFeatured ? deduped.first : nil
        let rest = featured != nil ? Array(deduped.dropFirst()) : deduped
        let sections = Self.group(rest)

        return Group {
            if let featured {
                Section {
                    articleCardRow(article: featured, featured: true, counts: counts)
                }
            }

            ForEach(sections, id: \.0) { section, sectionArticles in
                Section(section) {
                    ForEach(sectionArticles) { article in
                        articleCardRow(article: article, featured: false, counts: counts)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func articleCardRow(article: Article, featured: Bool, counts: [String: Int]) -> some View {
        let extraFeedCount = article.url.isEmpty ? 0 : max(0, (counts[article.url] ?? 1) - 1)
        Button {
            selectedArticle = article
        } label: {
            ArticleRowView(
                article: article,
                featured: featured,
                additionalFeedCount: extraFeedCount
            )
        }
        .buttonStyle(.plain)
        .contextMenu { ArticleContextMenu(article: article) }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
