import SwiftUI
import WebKit

/* ==================================================================
   B 方案：真实界面 = v5 效果图那套 HTML/CSS（Resources/app.html，由 build-app-html.js 生成），
   外面套原生 WKWebView；数据由原生 Store（WS）通过 window.BB.set(json) 推给页面，
   页面里的操作（发消息 / 打开会话）通过 messageHandlers.bb 回原生。
   好处：视觉就是效果图本身；动效用 CSS + WebKit 的惯性滚动。
   ================================================================== */

struct WebRoot: View {
    @EnvironmentObject var session: Session
    @StateObject private var store = Store()

    var body: some View {
        WebView(store: store)
            .ignoresSafeArea()
            .onAppear { store.connect(token: session.token) { session.logout() } }
            .onDisappear { store.disconnect() }
    }
}

struct WebView: UIViewRepresentable {
    @ObservedObject var store: Store

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.userContentController.add(context.coordinator, name: "bb")
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.bounces = false
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 16.4, *) { wv.isInspectable = true }
        if let url = Bundle.main.url(forResource: "app", withExtension: "html") {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            wv.loadHTMLString("<h3 style='font:16px -apple-system;padding:24px'>没找到 app.html</h3>", baseURL: nil)
        }
        context.coordinator.web = wv
        context.coordinator.store = store
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.store = store
        context.coordinator.push()
    }

    func makeCoordinator() -> Coord { Coord() }

    final class Coord: NSObject, WKScriptMessageHandler {
        weak var web: WKWebView?
        var store: Store?
        private var last = ""

        func userContentController(_ u: WKUserContentController, didReceive m: WKScriptMessage) {
            guard let d = m.body as? [String: Any], let op = d["op"] as? String else { return }
            Task { @MainActor [weak self] in
                guard let s = self?.store else { return }
                switch op {
                case "send":
                    if let cid = d["cid"] as? String, let text = d["text"] as? String { s.send(to: cid, text: text) }
                case "open":
                    if let cid = d["cid"] as? String { s.markRead(cid) }
                case "profile":
                    if let uid = d["uid"] as? String { s.markRead(uid) }
                default: break
                }
            }
        }

        @MainActor func push() {
            guard let store, let web else { return }
            let json = store.webPayload()
            guard json != last else { return }
            last = json
            web.evaluateJavaScript("window.BB && window.BB.set(\(json))")
        }
    }
}
