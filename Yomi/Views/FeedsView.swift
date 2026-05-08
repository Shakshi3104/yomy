import SwiftUI
import SwiftData

struct FeedsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Feed.createdAt) private var feeds: [Feed]

    @State private var showAddFeed = false
    @State private var feedToManage: Feed?

    private var groupedFeeds: [(String, [Feed])] {
        let groups = Dictionary(grouping: feeds, by: \.category)
        return groups.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedFeeds, id: \.0) { category, categoryFeeds in
                    Section(category) {
                        ForEach(categoryFeeds) { feed in
                            NavigationLink {
                                FeedDetailView(feed: feed)
                            } label: {
                                FeedRowView(feed: feed)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    try? FeedService.shared.deleteFeed(feed, context: context)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                                Button {
                                    feedToManage = feed
                                } label: {
                                    Label("編集", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("フィード")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFeed = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFeed) {
                AddFeedView()
            }
            .sheet(item: $feedToManage) { feed in
                FeedManageView(feed: feed)
            }
            .overlay {
                if feeds.isEmpty {
                    ContentUnavailableView(
                        "フィードがありません",
                        systemImage: "list.bullet",
                        description: Text("右上の + からフィードを追加してください")
                    )
                }
            }
        }
    }
}
