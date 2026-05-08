import SwiftData
import Foundation

@Model
final class Category {
    var name: String
    var sortOrder: Int

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
