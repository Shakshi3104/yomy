import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showsNewSheet = false
    @State private var editingCategory: Category?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.iconName)
                            .frame(width: 24)
                            .foregroundStyle(.primary)
                        Text(category.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                Button {
                    showsNewSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showsNewSheet) {
            NavigationStack {
                CategoryEditView()
            }
        }
        .sheet(item: $editingCategory) { category in
            NavigationStack {
                CategoryEditView(category: category)
            }
        }
    }
}
