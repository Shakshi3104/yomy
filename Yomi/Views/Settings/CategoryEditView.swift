import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: Category

    @State private var name: String
    @State private var iconName: String
    @State private var showIconPicker = false

    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _iconName = State(initialValue: category.iconName)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Category name", text: $name)
                    .textInputAutocapitalization(.words)
            }

            Section("Icon") {
                Button {
                    showIconPicker = true
                } label: {
                    HStack {
                        Image(systemName: iconName)
                            .frame(width: 28)
                            .foregroundStyle(.primary)
                        Text("Choose Icon")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .tint(.primary)
            }
        }
        .navigationTitle("Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    save()
                    dismiss()
                }
                .disabled(trimmedName.isEmpty)
            }
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selection: $iconName)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func save() {
        let newName = trimmedName
        guard !newName.isEmpty else { return }
        category.name = newName
        category.iconName = iconName
        try? context.save()
    }
}
