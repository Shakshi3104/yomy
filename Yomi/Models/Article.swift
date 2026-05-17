import SwiftData
import Foundation

@Model
final class Article {
    var id: UUID
    var guid: String
    var url: String
    var title: String
    var summary: String
    var imageURL: String?
    var author: String
    var publishedAt: Date
    var isRead: Bool
    var isSaved: Bool
    var savedAt: Date?
    var createdAt: Date

    var feed: Feed?

    init(
        guid: String,
        url: String,
        title: String,
        summary: String = "",
        imageURL: String? = nil,
        author: String = "",
        publishedAt: Date,
        feed: Feed? = nil
    ) {
        self.id = UUID()
        self.guid = guid
        self.url = url
        self.title = title
        self.summary = summary
        self.imageURL = imageURL
        self.author = author
        self.publishedAt = publishedAt
        self.isRead = false
        self.isSaved = false
        self.savedAt = nil
        self.createdAt = Date()
        self.feed = feed
    }
}
