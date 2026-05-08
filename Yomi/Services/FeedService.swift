import Foundation
import SwiftData

private let ogFetchConcurrency = 5

@MainActor
final class FeedService {
    static let shared = FeedService()

    func refresh(feed: Feed, context: ModelContext) async throws {
        let parsed = try await RSSFetcher.shared.fetch(url: feed.url)

        if feed.title.isEmpty || feed.title == feed.url {
            feed.title = parsed.title
        }
        if feed.siteURL.isEmpty {
            feed.siteURL = parsed.siteURL
        }
        feed.fetchedAt = Date()

        let existingByGUID = Dictionary(uniqueKeysWithValues: feed.articles.map { ($0.guid, $0) })
        var needsOGFetch: [(Article, String)] = []

        for parsedArticle in parsed.articles {
            if let existing = existingByGUID[parsedArticle.guid] {
                // 既存記事で imageURL がまだ未取得なら OG フェッチ対象に追加
                if existing.imageURL == nil && !parsedArticle.url.isEmpty {
                    needsOGFetch.append((existing, parsedArticle.url))
                }
                continue
            }
            let article = Article(
                guid: parsedArticle.guid,
                url: parsedArticle.url,
                title: parsedArticle.title,
                summary: parsedArticle.summary,
                imageURL: parsedArticle.imageURL,
                author: parsedArticle.author,
                publishedAt: parsedArticle.publishedAt,
                feed: feed
            )
            context.insert(article)
            feed.articles.append(article)

            if parsedArticle.imageURL == nil && !parsedArticle.url.isEmpty {
                needsOGFetch.append((article, parsedArticle.url))
            }
        }

        try context.save()

        // OG フェッチ — 新規・既存問わず imageURL が nil な記事を並列処理（最大 5 並列）
        await withTaskGroup(of: Void.self) { group in
            var running = 0
            for (article, articleURL) in needsOGFetch {
                if running >= ogFetchConcurrency {
                    await group.next()
                    running -= 1
                }
                group.addTask {
                    if let url = await OGImageFetcher.shared.fetch(articleURL: articleURL) {
                        await MainActor.run { article.imageURL = url }
                    }
                }
                running += 1
            }
        }

        if !needsOGFetch.isEmpty {
            try context.save()
        }
    }

    func refreshAll(feeds: [Feed], context: ModelContext) async {
        await withTaskGroup(of: Void.self) { group in
            for feed in feeds {
                group.addTask {
                    try? await self.refresh(feed: feed, context: context)
                }
            }
        }
    }

    func addFeed(url: String, category: String, context: ModelContext) async throws -> Feed {
        let normalizedURL = url.hasPrefix("http") ? url : "https://\(url)"
        let parsed = try await RSSFetcher.shared.fetch(url: normalizedURL)

        let feed = Feed(
            url: normalizedURL,
            title: parsed.title.isEmpty ? normalizedURL : parsed.title,
            siteURL: parsed.siteURL,
            category: category
        )
        context.insert(feed)

        var needsOGFetch: [(Article, String)] = []

        for parsedArticle in parsed.articles {
            let article = Article(
                guid: parsedArticle.guid,
                url: parsedArticle.url,
                title: parsedArticle.title,
                summary: parsedArticle.summary,
                imageURL: parsedArticle.imageURL,
                author: parsedArticle.author,
                publishedAt: parsedArticle.publishedAt,
                feed: feed
            )
            context.insert(article)
            feed.articles.append(article)

            if parsedArticle.imageURL == nil && !parsedArticle.url.isEmpty {
                needsOGFetch.append((article, parsedArticle.url))
            }
        }

        try context.save()

        await withTaskGroup(of: Void.self) { group in
            var running = 0
            for (article, articleURL) in needsOGFetch {
                if running >= ogFetchConcurrency {
                    await group.next()
                    running -= 1
                }
                group.addTask {
                    if let url = await OGImageFetcher.shared.fetch(articleURL: articleURL) {
                        await MainActor.run { article.imageURL = url }
                    }
                }
                running += 1
            }
        }

        if !needsOGFetch.isEmpty {
            try context.save()
        }

        return feed
    }

    func deleteFeed(_ feed: Feed, context: ModelContext) throws {
        context.delete(feed)
        try context.save()
    }

    func markAllRead(feed: Feed, context: ModelContext) throws {
        for article in feed.articles where !article.isRead {
            article.isRead = true
        }
        try context.save()
    }
}
