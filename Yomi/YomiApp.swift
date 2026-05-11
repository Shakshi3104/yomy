import SwiftUI
import SwiftData

@main
struct YomiApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Feed.self, Article.self, Category.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        seedDefaultCategoryIfNeeded()
        BackgroundRefreshService.register()
        BackgroundRefreshService.schedule()
    }

    private func seedDefaultCategoryIfNeeded() {
        let key = "yomy.didSeedDefaultCategory"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let context = ModelContext(container)
        context.insert(Category(name: "General", sortOrder: 0))
        try? context.save()
        UserDefaults.standard.set(true, forKey: key)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    BackgroundRefreshService.schedule()
                }
        }
    }
}
