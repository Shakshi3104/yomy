import SwiftUI
import WebKit

struct ArticleWebView: View {
    let article: Article
    @Environment(\.modelContext) private var context

    var body: some View {
        WebViewRepresentable(url: URL(string: article.url))
            .navigationTitle(article.feed?.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            article.isSaved.toggle()
                            try? context.save()
                        } label: {
                            Image(systemName: article.isSaved ? "bookmark.fill" : "bookmark")
                        }
                        ShareLink(item: URL(string: article.url)!) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .onAppear {
                if !article.isRead {
                    article.isRead = true
                    try? context.save()
                }
            }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else { return }
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}
