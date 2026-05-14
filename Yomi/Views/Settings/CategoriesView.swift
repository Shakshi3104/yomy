import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var newCategoryName = ""
    @State private var showAddAlert = false

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
                Button {
                    showAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Category", isPresented: $showAddAlert) {
            TextField("Category name", text: $newCategoryName)
                .textInputAutocapitalization(.words)
            Button("Add") { addCategory() }
                .disabled(trimmedName.isEmpty)
            Button("Cancel", role: .cancel) {
                newCategoryName = ""
            }
        }
    }

    private var trimmedName: String {
        newCategoryName.trimmingCharacters(in: .whitespaces)
    }

    private func addCategory() {
        let name = trimmedName
        guard !name.isEmpty,
              !categories.contains(where: { $0.name == name }) else {
            newCategoryName = ""
            return
        }
        let cat = Category(name: name, sortOrder: categories.count)
        context.insert(cat)
        try? context.save()
        newCategoryName = ""
    }
}
