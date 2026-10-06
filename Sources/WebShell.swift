import SwiftUI
import WebKit

/// 一个最小的网页壳：把打包进来的 HTML 显示出来。
/// M0 用它看我们的 55 屏设计稿；以后「关于 / 帮助 / 推送教程」这类页也走它。
struct WebShell: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let wv = WKWebView(frame: .zero, configuration: cfg)
        if let url = Bundle.main.url(forResource: "mobile-ui", withExtension: "html") {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            wv.loadHTMLString("<h3 style='font-family:-apple-system;padding:20px'>没找到 mobile-ui.html</h3>", baseURL: nil)
        }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
