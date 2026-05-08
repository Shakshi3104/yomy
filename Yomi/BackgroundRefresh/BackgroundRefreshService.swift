import Foundation
import BackgroundTasks
import SwiftData

final class BackgroundRefreshService {
    static let taskIdentifier = "com.minsc.yomi.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleAppRefresh(task: BGAppRefreshTask) {
        schedule()

        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task {
            do {
                let container = try ModelContainer(for: Feed.self, Article.self, Category.self)
                let context = ModelContext(container)
                let feeds = try context.fetch(FetchDescriptor<Feed>())
                await FeedService.shared.refreshAll(feeds: feeds, context: context)
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
