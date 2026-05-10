import SwiftUI
import SwiftData
import WidgetKit

struct LatestView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Article.publishedAt, order: .reverse) private var articles: [Article]
    @Query private var feeds: [Feed]

    @State private var isRefreshing = false
    @State private var navigateToFeatured: Article?
    @State private var showSettings = false

    private var featuredArticle: Article? {
        articles.first
    }

    private var groupedArticles: [(String, [Article])] {
        let rest = featuredArticle != nil ? Array(articles.dropFirst()) : articles
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let groups = Dictionary(grouping: rest) { article -> String in
            if cal.isDateInToday(article.publishedAt) { return "Today" }
            if cal.isDateInYesterday(article.publishedAt) { return "Yesterday" }
            return formatter.string(from: article.publishedAt)
        }
        let order = ["Today", "Yesterday"]
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
                        Button {
                            navigateToFeatured = featured
                        } label: {
                            FeaturedArticleCard(article: featured)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }

                ForEach(groupedArticles, id: \.0) { section, sectionArticles in
                    Section(section) {
                        ForEach(sectionArticles) { article in
                            NavigationLink(value: article) {
                                ArticleRowView(article: article)
                            }
                            .contextMenu { ArticleContextMenu(article: article) }
                        }
                    }
                }
            }
            .navigationTitle("Latest")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(for: Article.self) { article in
                ArticleWebView(article: article)
            }
            .navigationDestination(item: $navigateToFeatured) { article in
                ArticleWebView(article: article)
            }
            .refreshable {
                await refresh()
            }
            .onAppear {
                updateWidgetData()
            }
            .onChange(of: articles) {
                updateWidgetData()
            }
            .overlay {
                if articles.isEmpty && !isRefreshing {
                    ContentUnavailableView(
                        "No Articles",
                        systemImage: "newspaper",
                        description: Text("Add a feed to get started")
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

    private func updateWidgetData() {
        guard !articles.isEmpty else { return }
        let top = Array(articles.prefix(10))
        let widgetArticles = top.map { article in
            WidgetArticle(
                id: article.id.uuidString,
                title: article.title,
                feedTitle: article.feed?.title ?? "",
                url: article.url,
                imageURL: article.imageURL,
                publishedAt: article.publishedAt
            )
        }
        WidgetDataStore.save(widgetArticles)

        let keepIDs = Set(widgetArticles.map(\.id))
        WidgetDataStore.cleanUpImages(keeping: keepIDs)

        Task.detached {
            await cacheWidgetImages(top)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private nonisolated func cacheWidgetImages(_ articles: [Article]) async {
        await withTaskGroup(of: Void.self) { group in
            for article in articles {
                guard let urlString = article.imageURL,
                      let url = URL(string: urlString) else { continue }
                if WidgetDataStore.loadImage(for: article.id.uuidString) != nil { continue }
                group.addTask {
                    guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
                    WidgetDataStore.cacheImage(data: data, for: article.id.uuidString)
                }
            }
        }
    }
}
