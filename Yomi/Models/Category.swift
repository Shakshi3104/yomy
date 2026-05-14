import SwiftData
import Foundation

@Model
final class Category {
    var name: String = ""
    var sortOrder: Int = 0
    var iconName: String = "tag"

    init(name: String, sortOrder: Int = 0, iconName: String = "tag") {
        self.name = name
        self.sortOrder = sortOrder
        self.iconName = iconName
    }
}
