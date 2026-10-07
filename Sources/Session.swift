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
            /* ⚠️ 2026-10-07 修的真 bug：/api/login 的返回体里**没有 me 这一层**，字段是平铺的
               （ok / token / userId / name / account / email / bbjiId / avatar）。
               以前只读 me[...] → 全都读不到，就退成"用户手打的那个账号"——
               用户用邮箱登录时，「我」页和资料页的 BB鸡号就变成了邮箱，跟电脑端对不上。
               现在平铺字段优先，同时兼容 me 那一层。 */
            let nm = (r["name"] as? String) ?? (me["name"] as? String) ?? ""
            myName = nm.isEmpty ? (UserDefaults.standard.string(forKey: "bbji_nick") ?? account) : nm
            myId = (r["bbjiId"] as? String) ?? (me["bbjiId"] as? String)
                ?? (r["account"] as? String) ?? (me["account"] as? String) ?? account
            if let em = (r["email"] as? String), !em.isEmpty { UserDefaults.standard.set(em, forKey: "bbji_email") }
            if !nm.isEmpty { UserDefaults.standard.set(nm, forKey: "bbji_nick") }
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

    /* ==================== 0.0.2：注册 / 找回 / 改昵称（都是照设计稿那 5 屏做的） ==================== */

    /// 发验证码。返回 "" = 成功；否则是要显示给用户的错。
    func sendCode(_ email: String, scene: String) async -> String {
        let m = email.trimmingCharacters(in: .whitespaces)
        if !m.contains("@") { return "先填邮箱" }
        let r = await call("/api/send-code", ["email": m, "scene": scene])
        if (r["ok"] as? Bool) == true { return "" }
        return (r["error"] as? String) ?? "验证码发不出去，稍后再试"
    }

    /// 注册：账号 + 邮箱 + 验证码 + 密码（跟电脑端一个字段都不少）。成功后就等「取名字」那一步。
    func register(account: String, email: String, code: String, password: String) async -> String {
        err = ""
        let acc = account.trimmingCharacters(in: .whitespaces)
        let mail = email.trimmingCharacters(in: .whitespaces)
        if acc.isEmpty || mail.isEmpty || code.isEmpty || password.isEmpty { return "四项都要填" }
        if password.count < 6 { return "密码至少 6 位" }
        busy = true
        defer { busy = false }
        let r = await call("/api/register", ["account": acc, "email": mail, "code": code,
                                             "password": password, "name": acc])
        guard (r["ok"] as? Bool) == true else {
            let m = (r["error"] as? String) ?? "注册失败"
            err = m
            return m
        }
        token = (r["token"] as? String) ?? ""
        myName = (r["name"] as? String) ?? acc
        myId = (r["bbjiId"] as? String) ?? acc
        UserDefaults.standard.set(token, forKey: Self.tokenKey)
        UserDefaults.standard.set(["name": myName, "bbjiId": myId], forKey: Self.meKey)
        return ""
    }

    /// 找回密码：邮箱 + 验证码 + 新密码
    func resetPassword(email: String, code: String, password: String) async -> String {
        let mail = email.trimmingCharacters(in: .whitespaces)
        if mail.isEmpty || code.isEmpty { return "邮箱和验证码都要填" }
        if password.count < 6 { return "新密码至少 6 位" }
        busy = true
        defer { busy = false }
        let r = await call("/api/reset-password", ["email": mail, "code": code, "password": password])
        guard (r["ok"] as? Bool) == true else { return (r["error"] as? String) ?? "改不了，稍后再试" }
        return ""
    }

    /// 刚注册完先取个名字（不填就直接进，用账号当名字）
    func setNickname(_ name: String) async -> String {
        let n = name.trimmingCharacters(in: .whitespaces)
        if !n.isEmpty {
            let r = await call("/api/profile", ["token": token, "name": n])
            if (r["ok"] as? Bool) == true { myName = n }
        }
        UserDefaults.standard.set(["name": myName, "bbjiId": myId], forKey: Self.meKey)
        loggedIn = true
        return ""
    }

    private func call(_ path: String, _ body: [String: Any]) async -> [String: Any] {
        (try? await post(path, body)) ?? [:]
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
