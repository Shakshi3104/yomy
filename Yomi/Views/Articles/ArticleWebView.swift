import SwiftUI
import WebKit

struct ArticleWebView: View {
    let article: Article
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var navigator = WebViewNavigator()

    var body: some View {
        WebViewRepresentable(
            url: URL(string: article.url),
            navigator: navigator
        )
        .navigationTitle(article.feed?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
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
                .disabled(!navigator.canGoBack)

                Spacer()

                Button {
                    navigator.goForward()
                } label: {
                    Image(systemName: "chevron.forward")
                }
                .disabled(!navigator.canGoForward)
            }
        }
        .onAppear {
            if !article.isRead {
                FeedService.shared.setRead(article: article, isRead: true, context: context)
            }
        }
    }
}

/// Single source of truth for the WebView's navigation state. Holds a reference
/// to the live `WKWebView` so the toolbar can drive its history (`goBack` /
/// `goForward`), and exposes `canGoBack` / `canGoForward` as observable state so
/// the toolbar buttons enable/disable in step with the web view.
@Observable
final class WebViewNavigator {
    @ObservationIgnored fileprivate weak var webView: WKWebView?
    var canGoBack = false
    var canGoForward = false

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL?
    let navigator: WebViewNavigator

    func makeCoordinator() -> Coordinator {
        Coordinator(navigator: navigator)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        navigator.webView = webView
        context.coordinator.observe(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Load only once, on first appearance. Comparing against `url` would
        // reload the original article whenever the user follows an in-page link
        // (canGoBack/canGoForward state changes retrigger updateUIView), which
        // would defeat the back/forward navigation this view provides.
        guard let url, webView.url == nil else { return }
        webView.load(URLRequest(url: url))
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObserving()
    }

    final class Coordinator {
        private let navigator: WebViewNavigator
        private var backObservation: NSKeyValueObservation?
        private var forwardObservation: NSKeyValueObservation?

        init(navigator: WebViewNavigator) {
            self.navigator = navigator
        }

        func observe(_ webView: WKWebView) {
            // No `.initial`: it fires synchronously during makeUIView (inside the
            // SwiftUI update phase) and mutating observable state there triggers a
            // "Modifying state during view update" warning. The navigator defaults
            // to false, which already matches a fresh web view's history.
            backObservation = webView.observe(\.canGoBack, options: [.new]) { [navigator] webView, _ in
                navigator.canGoBack = webView.canGoBack
            }
            forwardObservation = webView.observe(\.canGoForward, options: [.new]) { [navigator] webView, _ in
                navigator.canGoForward = webView.canGoForward
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
