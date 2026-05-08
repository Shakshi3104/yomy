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
        BackgroundRefreshService.register()
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
