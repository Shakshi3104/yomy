import SwiftUI
import SwiftData

struct AddFeedView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var urlText = ""
    @State private var selectedCategory = ""
    @State private var newCategoryName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed URL") {
                    TextField("https://example.com/feed", text: $urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await addFeed() }
                    }
                    .disabled(urlText.isEmpty || isLoading)
                }
            }
            .onAppear {
                guard selectedCategory.isEmpty else { return }
                if let general = categories.first(where: { $0.name == "General" }) {
                    selectedCategory = general.name
                } else if let first = categories.first {
                    selectedCategory = first.name
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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

    private func addFeed() async {
        isLoading = true
        errorMessage = nil
        do {
            let _ = try await FeedService.shared.addFeed(url: urlText, category: selectedCategory, context: context)
            dismiss()
        } catch {
            errorMessage = "Failed to fetch feed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
