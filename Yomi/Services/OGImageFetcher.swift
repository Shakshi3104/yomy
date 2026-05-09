import Foundation
import os.log

private let logger = Logger(subsystem: "com.shakshi.yomy", category: "OGImageFetcher")

// Fetches og:image / twitter:image from an article page.
// Reads only the first 64 KB — OG tags are always in <head>.
actor OGImageFetcher {
    static let shared = OGImageFetcher()

    // property= と name= 両方の形式に対応、前後順不問
    private static let ogImagePattern = #"(?i)<meta[^>]+(?:(?:property|name)=["']og:image["'][^>]+content=["']([^"']+)["']|content=["']([^"']+)["'][^>]+(?:property|name)=["']og:image["'])[^>]*>"#
    private static let twitterImagePattern = #"(?i)<meta[^>]+(?:name=["']twitter:image(?::src)?["'][^>]+content=["']([^"']+)["']|content=["']([^"']+)["'][^>]+name=["']twitter:image(?::src)?["'])[^>]*>"#

    private static let ogRegex = try! NSRegularExpression(pattern: ogImagePattern)
    private static let twitterRegex = try! NSRegularExpression(pattern: twitterImagePattern)

    func fetch(articleURL: String) async -> String? {
        guard let url = URL(string: articleURL) else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue(
            "Mozilla/5.0 (compatible; Yomi/1.0; +https://github.com/minsc-of-secrets/Yomi)",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return nil }
            guard http.statusCode < 400 else {
                logger.warning("OG fetch HTTP \(http.statusCode) for \(articleURL)")
                return nil
            }

            // Read at most 64 KB
            let chunk = data.prefix(64 * 1024)
            guard let body = String(data: chunk, encoding: .utf8) ?? String(data: chunk, encoding: .isoLatin1) else {
                logger.warning("OG fetch: failed to decode body for \(articleURL)")
                return nil
            }

            let range = NSRange(body.startIndex..., in: body)

            if let match = Self.ogRegex.firstMatch(in: body, range: range),
               let result = extractCapture(match: match, in: body) {
                logger.debug("OG image found (og): \(result) for \(articleURL)")
                return result
            }
            if let match = Self.twitterRegex.firstMatch(in: body, range: range),
               let result = extractCapture(match: match, in: body) {
                logger.debug("OG image found (twitter): \(result) for \(articleURL)")
                return result
            }
            logger.warning("OG image not found in HTML for \(articleURL)")
            return nil
        } catch {
            logger.warning("OG fetch error: \(error.localizedDescription) for \(articleURL)")
            return nil
        }
    }

    private func extractCapture(match: NSTextCheckingResult, in body: String) -> String? {
        for i in 1..<match.numberOfRanges {
            if let range = Range(match.range(at: i), in: body) {
                let value = String(body[range])
                if !value.isEmpty {
                    return value.htmlUnescaped
                }
            }
        }
        return nil
    }
}

private extension String {
    var htmlUnescaped: String {
        self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}
