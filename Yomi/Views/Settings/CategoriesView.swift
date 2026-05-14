import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink {
                    CategoryEditView(category: category)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.iconName)
                            .frame(width: 24)
                            .foregroundStyle(.primary)
                        Text(category.name)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    context.delete(categories[index])
                }
                try? context.save()
            }
        }
        .overlay {
            if categories.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "folder",
                    description: Text("Tap + to add a category")
                )
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CategoryEditView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
