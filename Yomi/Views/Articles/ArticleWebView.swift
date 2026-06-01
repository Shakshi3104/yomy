import SwiftUI
import WebKit

struct ArticleWebView: View {
    let article: Article
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var navigator = WebViewNavigator()
    @State private var canGoBack = false
    @State private var canGoForward = false

    var body: some View {
        WebViewRepresentable(
            url: URL(string: article.url),
            navigator: navigator,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward
        )
        .navigationTitle(article.feed?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    FeedService.shared.setSaved(article: article, isSaved: !article.isSaved, context: context)
                } label: {
                    Image(systemName: article.isSaved ? "bookmark.fill" : "bookmark")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let url = URL(string: article.url) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    navigator.goBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(!canGoBack)

                Spacer()

                Button {
                    navigator.goForward()
                } label: {
                    Image(systemName: "chevron.forward")
                }
                .disabled(!canGoForward)
            }
        }
        .onAppear {
            if !article.isRead {
                FeedService.shared.setRead(article: article, isRead: true, context: context)
            }
        }
    }
}

/// Holds a reference to the live `WKWebView` so the toolbar can drive its
/// navigation history (`goBack` / `goForward`).
@Observable
final class WebViewNavigator {
    fileprivate weak var webView: WKWebView?

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL?
    let navigator: WebViewNavigator
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(canGoBack: $canGoBack, canGoForward: $canGoForward)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        navigator.webView = webView
        context.coordinator.observe(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else { return }
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObserving()
    }

    final class Coordinator {
        @Binding private var canGoBack: Bool
        @Binding private var canGoForward: Bool
        private var backObservation: NSKeyValueObservation?
        private var forwardObservation: NSKeyValueObservation?

        init(canGoBack: Binding<Bool>, canGoForward: Binding<Bool>) {
            _canGoBack = canGoBack
            _canGoForward = canGoForward
        }

        func observe(_ webView: WKWebView) {
            backObservation = webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
                self?.canGoBack = webView.canGoBack
            }
            forwardObservation = webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
                self?.canGoForward = webView.canGoForward
            }
        }

        func stopObserving() {
            backObservation?.invalidate()
            forwardObservation?.invalidate()
            backObservation = nil
            forwardObservation = nil
        }
    }
}
