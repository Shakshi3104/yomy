import Foundation
import UIKit

struct WidgetArticle: Codable, Identifiable {
    var id: String
    var title: String
    var feedTitle: String
    var url: String
    var imageURL: String?
    var publishedAt: Date
}

enum WidgetDataStore {
    static let appGroupID = "group.com.minsc.yomi"
    private static let fileName = "widget_articles.json"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var fileURL: URL? {
        containerURL?.appendingPathComponent(fileName)
    }

    private static var imagesDir: URL? {
        guard let dir = containerURL?.appendingPathComponent("widget_images") else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(_ articles: [WidgetArticle]) {
        guard let url = fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(articles) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func load() -> [WidgetArticle] {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([WidgetArticle].self, from: data)) ?? []
    }

    static func cacheImage(data: Data, for articleID: String) {
        guard let dir = imagesDir else { return }
        let file = dir.appendingPathComponent(articleID)
        try? data.write(to: file, options: .atomic)
    }

    static func loadImage(for articleID: String) -> UIImage? {
        guard let dir = imagesDir else { return nil }
        let file = dir.appendingPathComponent(articleID)
        guard let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    static func cleanUpImages(keeping ids: Set<String>) {
        guard let dir = imagesDir,
              let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for file in files where !ids.contains(file) {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
        }
    }
}
