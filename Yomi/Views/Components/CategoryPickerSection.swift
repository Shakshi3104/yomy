import SwiftUI
import SwiftData

struct CategoryPickerSection: View {
    @Binding var selectedCategory: String
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var newCategoryName = ""
    @State private var showNewCategoryAlert = false

    var body: some View {
        Section("Category") {
            Menu {
                Button {
                    selectedCategory = ""
                } label: {
                    if selectedCategory.isEmpty {
                        Label("None", systemImage: "checkmark")
                    } else {
                        Text("None")
                    }
                }
                ForEach(categories) { cat in
                    Button {
                        selectedCategory = cat.name
                    } label: {
                        if selectedCategory == cat.name {
                            Label(cat.name, systemImage: "checkmark")
                        } else {
                            Text(cat.name)
                        }
                    }
                }
                Divider()
                Button {
                    showNewCategoryAlert = true
                } label: {
                    Label("New Category...", systemImage: "plus.circle")
                }
            } label: {
                HStack {
                    Text(selectedCategory.isEmpty ? "None" : selectedCategory)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
        }
        .alert("New Category", isPresented: $showNewCategoryAlert) {
            TextField("Category name", text: $newCategoryName)
                .textInputAutocapitalization(.words)
            Button("Add") { addCategory() }
                .disabled(trimmedNewCategoryName.isEmpty)
            Button("Cancel", role: .cancel) {
                newCategoryName = ""
            }
        }
    }

    private var trimmedNewCategoryName: String {
        newCategoryName.trimmingCharacters(in: .whitespaces)
    }

    private func addCategory() {
        let name = trimmedNewCategoryName
        guard !name.isEmpty,
              !categories.contains(where: { $0.name == name }) else {
            newCategoryName = ""
            return
        }
        let cat = Category(name: name, sortOrder: categories.count)
        context.insert(cat)
        try? context.save()
        selectedCategory = name
        newCategoryName = ""
    }
}
