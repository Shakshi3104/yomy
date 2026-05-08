import Foundation
import FeedKit

struct ParsedFeed {
    var title: String
    var siteURL: String
    var articles: [ParsedArticle]
}

struct ParsedArticle {
    var guid: String
    var url: String
    var title: String
    var summary: String
    var imageURL: String?
    var author: String
    var publishedAt: Date
}

actor RSSFetcher {
    static let shared = RSSFetcher()

    func fetch(url: String) async throws -> ParsedFeed {
        guard let feedURL = URL(string: url) else {
            throw URLError(.badURL)
        }

        let parser = FeedParser(URL: feedURL)
        let result = await withCheckedContinuation { continuation in
            parser.parseAsync { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .success(let feed):
            return try parseFeed(feed, sourceURL: url)
        case .failure(let error):
            throw error
        }
    }

    func fetchAll(feeds: [Feed]) async {
        await withTaskGroup(of: Void.self) { group in
            for feed in feeds {
                group.addTask {
                    _ = try? await self.fetch(url: feed.url)
                }
            }
        }
    }

    private func parseFeed(_ feed: FeedKit.Feed, sourceURL: String) throws -> ParsedFeed {
        switch feed {
        case .rss(let rss):
            return parseRSS(rss)
        case .atom(let atom):
            return parseAtom(atom)
        case .json(let json):
            return parseJSON(json)
        }
    }

    private func parseRSS(_ feed: RSSFeed) -> ParsedFeed {
        let articles = (feed.items ?? []).compactMap { item -> ParsedArticle? in
            guard let title = item.title, let link = item.link else { return nil }
            let guid = item.guid?.value ?? link
            let imageURL = extractImageURL(from: item)
            return ParsedArticle(
                guid: guid,
                url: link,
                title: title,
                summary: item.description?.strippingHTML() ?? "",
                imageURL: imageURL,
                author: item.author ?? item.dublinCore?.dcCreator ?? "",
                publishedAt: item.pubDate ?? Date()
            )
        }
        return ParsedFeed(
            title: feed.title ?? "",
            siteURL: feed.link ?? "",
            articles: articles
        )
    }

    private func parseAtom(_ feed: AtomFeed) -> ParsedFeed {
        let articles = (feed.entries ?? []).compactMap { entry -> ParsedArticle? in
            guard let title = entry.title else { return nil }
            let link = entry.links?.first?.attributes?.href ?? ""
            guard !link.isEmpty else { return nil }
            let guid = entry.id ?? link
            let summary = entry.summary?.value ?? entry.content?.value ?? ""
            return ParsedArticle(
                guid: guid,
                url: link,
                title: title,
                summary: summary.strippingHTML(),
                imageURL: nil,
                author: entry.authors?.first?.name ?? "",
                publishedAt: entry.published ?? entry.updated ?? Date()
            )
        }
        return ParsedFeed(
            title: feed.title ?? "",
            siteURL: feed.links?.first?.attributes?.href ?? "",
            articles: articles
        )
    }

    private func parseJSON(_ feed: JSONFeed) -> ParsedFeed {
        let articles = (feed.items ?? []).compactMap { item -> ParsedArticle? in
            guard let title = item.title, let link = item.url else { return nil }
            return ParsedArticle(
                guid: item.id ?? link,
                url: link,
                title: title,
                summary: item.summary ?? item.contentText ?? "",
                imageURL: item.image,
                author: item.author?.name ?? "",
                publishedAt: item.datePublished ?? Date()
            )
        }
        return ParsedFeed(
            title: feed.title ?? "",
            siteURL: feed.homePageURL ?? "",
            articles: articles
        )
    }

    private func extractImageURL(from item: RSSFeedItem) -> String? {
        // media:thumbnail
        if let thumbnail = item.media?.mediaThumbnails?.first?.attributes?.url {
            return thumbnail
        }
        // media:content (image)
        if let content = item.media?.mediaContents?.first(where: {
            $0.attributes?.medium == "image"
        })?.attributes?.url {
            return content
        }
        // enclosure
        if let enc = item.enclosure?.attributes,
           let url = enc.url,
           let type = enc.type,
           type.hasPrefix("image") {
            return url
        }
        // first <img> from description HTML
        if let html = item.description {
            return extractFirstImageFromHTML(html)
        }
        return nil
    }

    private func extractFirstImageFromHTML(_ html: String) -> String? {
        let pattern = #"<img[^>]+src=[\"']([^\"']+)[\"']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return String(html[range])
    }
}

private extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        return attributed.string
    }
}
