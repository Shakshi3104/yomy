import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var feeds: [Feed]

    @State private var newCategoryName = ""
    @State private var showOPMLImporter = false
    @State private var showOPMLExporter = false
    @State private var opmlExportContent = ""
    @State private var importError: String?
    @State private var importSuccessCount = 0
    @State private var showImportResult = false

    var body: some View {
        NavigationStack {
            Form {
                categoriesSection
                opmlSection
                aboutSection
            }
            .navigationTitle("設定")
            .fileImporter(
                isPresented: $showOPMLImporter,
                allowedContentTypes: [.xml, UTType("public.opml") ?? .xml]
            ) { result in
                handleOPMLImport(result: result)
            }
            .fileExporter(
                isPresented: $showOPMLExporter,
                document: OPMLDocument(content: opmlExportContent),
                contentType: .xml,
                defaultFilename: "yomi-feeds.opml"
            ) { _ in }
            .alert("インポート完了", isPresented: $showImportResult) {
                Button("OK") {}
            } message: {
                if let err = importError {
                    Text(err)
                } else {
                    Text("\(importSuccessCount) 件のフィードを追加しました")
                }
            }
        }
    }

    private var categoriesSection: some View {
        Section("カテゴリ") {
            ForEach(categories) { category in
                Text(category.name)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    context.delete(categories[index])
                }
                try? context.save()
            }

            HStack {
                TextField("新しいカテゴリ", text: $newCategoryName)
                Button("追加") {
                    guard !newCategoryName.isEmpty else { return }
                    let cat = Category(name: newCategoryName, sortOrder: categories.count)
                    context.insert(cat)
                    try? context.save()
                    newCategoryName = ""
                }
                .disabled(newCategoryName.isEmpty)
            }
        }
    }

    private var opmlSection: some View {
        Section("OPML") {
            Button {
                opmlExportContent = OPMLManager.shared.exportOPML(feeds: feeds)
                showOPMLExporter = true
            } label: {
                Label("フィードをエクスポート", systemImage: "square.and.arrow.up")
            }

            Button {
                showOPMLImporter = true
            } label: {
                Label("OPMLをインポート", systemImage: "square.and.arrow.down")
            }
        }
    }

    private var aboutSection: some View {
        Section("アプリ情報") {
            LabeledContent("バージョン") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
            }
        }
    }

    private func handleOPMLImport(result: Result<URL, Error>) {
        importError = nil
        importSuccessCount = 0

        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let opmlFeeds = try OPMLManager.shared.importOPML(data: data)
                Task {
                    var added = 0
                    for opmlFeed in opmlFeeds {
                        if let _ = try? await FeedService.shared.addFeed(
                            url: opmlFeed.xmlURL,
                            category: opmlFeed.category,
                            context: context
                        ) { added += 1 }
                    }
                    await MainActor.run {
                        importSuccessCount = added
                        showImportResult = true
                    }
                }
            } catch {
                importError = error.localizedDescription
                showImportResult = true
            }
        case .failure(let error):
            importError = error.localizedDescription
            showImportResult = true
        }
    }
}

struct OPMLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.xml] }
    var content: String

    init(content: String) { self.content = content }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(content.utf8))
    }
}
