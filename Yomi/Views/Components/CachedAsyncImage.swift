import SwiftUI
import UIKit

// In-memory image cache shared across the app lifetime.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 300
        c.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        return c
    }()

    func get(_ url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func set(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage? = nil

    init(
        url: URL,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            if let cached = ImageCache.shared.get(url) {
                uiImage = cached
                return
            }
            uiImage = nil
            // ダウンロードとデコードはメインスレッド外で完了させる。
            // UIImage(data:) はデコードを遅延し、初回描画時にメインスレッドで走るため、
            // これをやらないとスクロールでセルが出るたびに固まる。
            let loaded = await Self.loadImage(url: url)
            guard !Task.isCancelled, let loaded else { return }
            uiImage = loaded
        }
    }

    /// ネットワーク取得 → デコード確定(byPreparingForDisplay)まで main actor 外で行い、
    /// 描画時にメインスレッドでデコードが発生しないようにする。結果はキャッシュへ格納する。
    nonisolated private static func loadImage(url: URL) async -> UIImage? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode < 400,
              let image = UIImage(data: data) else { return nil }
        let decoded = await image.byPreparingForDisplay() ?? image
        ImageCache.shared.set(decoded, for: url)
        return decoded
    }
}
