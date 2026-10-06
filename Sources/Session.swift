import Foundation
import SwiftUI

/// 登录态 + 跟服务器说话的那一层。
/// M0 只要能：登录、把 token 存下来、重开还登着。
@MainActor
final class Session: ObservableObject {
    static let apiBase = "https://bbji.xkmd.cn"
    private static let tokenKey = "bbji_token"
    private static let meKey = "bbji_me"

    @Published var loggedIn = false
    @Published var myName = ""
    @Published var myId = ""
    @Published var busy = false
    @Published var err = ""

    private(set) var token = ""

    init() {
        token = UserDefaults.standard.string(forKey: Self.tokenKey) ?? ""
        if !token.isEmpty {
            let me = UserDefaults.standard.dictionary(forKey: Self.meKey) ?? [:]
            myName = (me["name"] as? String) ?? ""
            myId = (me["bbjiId"] as? String) ?? (me["account"] as? String) ?? ""
            loggedIn = true          // 先按"登着"进主界面，M1 再加一次 token 校验
        }
    }

    /// 设备标识：第一次装的时候生成一个，之后一直用它（跟电脑端一样，服务端按设备算 token）
    private var deviceId: String {
        if let d = UserDefaults.standard.string(forKey: "bbji_device"), !d.isEmpty { return d }
        let d = UUID().uuidString
        UserDefaults.standard.set(d, forKey: "bbji_device")
        return d
    }

    func login(account: String, password: String) async {
        err = ""
        if account.isEmpty || password.isEmpty { err = "请填账号和密码"; return }
        busy = true
        defer { busy = false }
        let body: [String: Any] = [
            "account": account,
            "password": password,
            "device": ["id": deviceId, "name": "\(UIDeviceName())", "kind": "ios"],
        ]
        do {
            let r = try await post("/api/login", body)
            guard let ok = r["ok"] as? Bool, ok else {
                err = (r["error"] as? String) ?? "登录失败"
                return
            }
            token = (r["token"] as? String) ?? ""
            let me = (r["me"] as? [String: Any]) ?? [:]
            myName = (me["name"] as? String) ?? account
            myId = (me["bbjiId"] as? String) ?? (me["account"] as? String) ?? account
            UserDefaults.standard.set(token, forKey: Self.tokenKey)
            UserDefaults.standard.set(["name": myName, "bbjiId": myId], forKey: Self.meKey)
            loggedIn = true
        } catch {
            err = "连不上服务器，检查网络"
        }
    }

    func logout() {
        token = ""; myName = ""; myId = ""; loggedIn = false
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: Self.meKey)
    }

    private func post(_ path: String, _ body: [String: Any]) async throws -> [String: Any] {
        var req = URLRequest(url: URL(string: Self.apiBase + path)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}

private func UIDeviceName() -> String {
    #if canImport(UIKit)
    return "iPhone"
    #else
    return "iOS"
    #endif
}
