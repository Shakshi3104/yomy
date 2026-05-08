import SwiftUI
import SwiftData

struct LatestView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Article.publishedAt, order: .reverse) private var articles: [Article]
    @Query private var feeds: [Feed]

    @State private var isRefreshing = false

    private var featuredArticle: Article? {
        articles.first
    }

    private var groupedArticles: [(String, [Article])] {
        let rest = featuredArticle != nil ? Array(articles.dropFirst()) : articles
        let groups = Dictionary(grouping: rest) { article -> String in
            let cal = Calendar.current
            if cal.isDateInToday(article.publishedAt) { return "今日" }
            if cal.isDateInYesterday(article.publishedAt) { return "昨日" }
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: article.publishedAt)
        }
        let order = ["今日", "昨日"]
        return groups.sorted { a, b in
            let ia = order.firstIndex(of: a.key) ?? Int.max
            let ib = order.firstIndex(of: b.key) ?? Int.max
            if ia != ib { return ia < ib }
            return a.key > b.key
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let featured = featuredArticle {
                    Section {
                        NavigationLink(value: featured) {
                            FeaturedArticleCard(article: featured)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .listRowSeparator(.hidden)
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            featured.isRead = true
                        })
                    }
                }

                ForEach(groupedArticles, id: \.0) { section, sectionArticles in
                    Section(section) {
                        ForEach(sectionArticles) { article in
                            NavigationLink(value: article) {
                                ArticleRowView(article: article)
                            }
                            .contextMenu { ArticleContextMenu(article: article) }
                            .simultaneousGesture(TapGesture().onEnded {
                                article.isRead = true
                            })
                        }
                    }
                }
            }
            .navigationTitle("最新")
            .navigationDestination(for: Article.self) { article in
                ArticleWebView(article: article)
            }
            .refreshable {
                await refresh()
            }
            .overlay {
                if articles.isEmpty && !isRefreshing {
                    ContentUnavailableView(
                        "記事がありません",
                        systemImage: "newspaper",
                        description: Text("フィードを追加してください")
                    )
                }
            }
        }
    }

    private func refresh() async {
        isRefreshing = true
        await FeedService.shared.refreshAll(feeds: feeds, context: context)
        isRefreshing = false
    }
}
