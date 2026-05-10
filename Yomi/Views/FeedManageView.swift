import SwiftUI
import SwiftData

struct FeedManageView: View {
    let feed: Feed
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedCategory: String
    @State private var newCategoryName = ""

    init(feed: Feed) {
        self.feed = feed
        self._selectedCategory = State(initialValue: feed.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed Info") {
                    LabeledContent("Title", value: feed.title)
                    LabeledContent("URL") {
                        Text(feed.url)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag("")
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.name)
                        }
                    }

                    HStack {
                        TextField("New category", text: $newCategoryName)
                        Button("Add") { addCategory() }
                            .disabled(trimmedNewCategoryName.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        feed.category = selectedCategory
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }

    private var trimmedNewCategoryName: String {
        newCategoryName.trimmingCharacters(in: .whitespaces)
    }

    private func addCategory() {
        let name = trimmedNewCategoryName
        guard !name.isEmpty,
              !categories.contains(where: { $0.name == name }) else { return }
        let cat = Category(name: name, sortOrder: categories.count)
        context.insert(cat)
        try? context.save()
        selectedCategory = name
        newCategoryName = ""
    }
}
