import SwiftUI
import SwiftData

struct AddFeedView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var urlText = ""
    @State private var selectedCategory = ""
    @State private var newCategoryName = ""
    @State private var showNewCategoryAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed URL") {
                    ZStack(alignment: .leading) {
                        if urlText.isEmpty {
                            Text(verbatim: "https://example.com/feed")
                                .foregroundStyle(.secondary)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $urlText)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

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
            .alert("New Category", isPresented: $showNewCategoryAlert) {
                TextField("Category name", text: $newCategoryName)
                    .textInputAutocapitalization(.words)
                Button("Add") { addCategory() }
                    .disabled(trimmedNewCategoryName.isEmpty)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
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
