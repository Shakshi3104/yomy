import Foundation
import SwiftData

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

        let existingGUIDs = Set(feed.articles.map(\.guid))
        for parsedArticle in parsed.articles {
            guard !existingGUIDs.contains(parsedArticle.guid) else { continue }
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
        }

        try context.save()
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
        }

        try context.save()
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
