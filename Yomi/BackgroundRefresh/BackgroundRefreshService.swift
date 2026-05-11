import Foundation
import BackgroundTasks
import SwiftData

final class BackgroundRefreshService {
    static let taskIdentifier = "com.shakshi.yomy.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[BackgroundRefresh] schedule failed: \(error)")
        }
    }

    private static func handleAppRefresh(task: BGAppRefreshTask) {
        schedule()

        let work = Task {
            do {
                let container = try ModelContainer(for: Feed.self, Article.self, Category.self)
                let context = ModelContext(container)
                let feeds = try context.fetch(FetchDescriptor<Feed>())
                await FeedService.shared.refreshAll(feeds: feeds, context: context)
                task.setTaskCompleted(success: !Task.isCancelled)
            } catch {
                print("[BackgroundRefresh] refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            work.cancel()
        }
    }
}
