import Foundation
import SwiftUI

/* ==================== 数据（跟服务端 WS 说好话的那一层） ====================
   服务端协议（跟电脑端一模一样）：
     连上 wss://bbji.xkmd.cn → 收 {t:'hello'} → 发 {t:'auth', token}
     → 收 {t:'authed', userId, me} → 收 {t:'people', list} / {t:'social', friends, groups, allIn}
     → 发 {t:'sync', since:0} → 收 {t:'sync', list:[...]}
     收发消息：{t:'send', to, text, cid} → 回来 {t:'ack', cid, id, ts}；对方来的 {t:'msg', msg}
     群里：to = 'all'（全员群）或 'g…'；单聊：to = 对方 userId
   ======================================================================== */

struct Person: Identifiable, Equatable {
    let id: String
    var name: String
    var online: Bool = false
    var remark: String = ""
    var account: String = ""
    var avatar: String = ""
    var display: String { remark.isEmpty ? name : remark }
}

struct Group: Identifiable, Equatable {
    let id: String
    var name: String
    var members: [String] = []
}

struct Msg: Identifiable, Equatable {
    let id: String
    var from: String
    var to: String
    var text: String
    var ts: Double
    var kind: String = "text"
    var recalled: Bool = false
    var read: Int = 0
}

/// 会话（消息列表里的一行）
struct Conv: Identifiable {
    let id: String            // 对方 id / 群 id
    var name: String
    var text: String
    var ts: Double
    var unread: Int
    var isGroup: Bool
    var online: Bool
}

@MainActor
final class Store: ObservableObject {
    @Published var connected = false
    @Published var people: [String: Person] = [:]
    @Published var friends: [Person] = []
    @Published var groups: [Group] = []
    @Published var allIn = false
    @Published var msgs: [Msg] = []
    @Published var lastRead: [String: Double] = [:]
    @Published var meName = ""
    @Published var meId = ""

    var onAuthFail: (() -> Void)?

    private var task: URLSessionWebSocketTask?
    private var token = ""
    private var ping: Timer?
    private var retry: Timer?
    private let wsURL = URL(string: "wss://bbji.xkmd.cn")!

    /* ---------- 连上 / 断开 ---------- */
    func connect(token: String, onFail: (() -> Void)? = nil) {
        self.token = token
        self.onAuthFail = onFail
        guard !token.isEmpty else { return }
        if let t = task { t.cancel(with: .goingAway, reason: nil) }
        let t = URLSession.shared.webSocketTask(with: wsURL)
        task = t
        t.resume()
        readLoop(t)
        ping?.invalidate()
        ping = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.raw(["t": "ping"]) }
        }
    }

    func disconnect() {
        ping?.invalidate(); retry?.invalidate()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil; connected = false; token = ""
    }

    private func readLoop(_ t: URLSessionWebSocketTask) {
        t.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                Task { @MainActor in
                    self.connected = false
                    // 断了就 3 秒后重连（只要还登录着）
                    self.retry?.invalidate()
                    self.retry = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
                        Task { @MainActor in
                            guard let s = self, !s.token.isEmpty else { return }
                            s.connect(token: s.token, onFail: s.onAuthFail)
                        }
                    }
                }
            case .success(let m):
                if case .string(let s) = m { Task { @MainActor in self.handle(s) } }
                self.readLoop(t)
            }
        }
    }

    private func raw(_ obj: [String: Any]) {
        guard let t = task else { return }
        guard let d = try? JSONSerialization.data(withJSONObject: obj),
              let s = String(data: d, encoding: .utf8) else { return }
        t.send(.string(s)) { _ in }
    }

    /* ---------- 收帧 ---------- */
    private func handle(_ text: String) {
        guard let d = text.data(using: .utf8),
              let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let t = o["t"] as? String else { return }
        switch t {
        case "hello":
            raw(["t": "auth", token: token])
        case "authed":
            connected = true
            meUserId = (o["userId"] as? String) ?? ""
            if let me = o["me"] as? [String: Any] {
                meName = (me["name"] as? String) ?? ""
                meId = (me["bbjiId"] as? String) ?? (me["account"] as? String) ?? ""
            }
            raw(["t": "sync", since: 0])
        case "auth_err":
            connected = false
            onAuthFail?()
        case "people":
            applyPeople(o["list"] as? [[String: Any]] ?? [])
        case "social":
            applySocial(o)
        case "sync":
            if let list = o["list"] as? [[String: Any]] {
                msgs = list.compactMap(msgOf).sorted { $0.ts < $1.ts }
                loadRead()
            }
        case "msg":
            if let m = o["msg"] as? [String: Any], let x = msgOf(m) {
                if !msgs.contains(where: { $0.id == x.id }) { msgs.append(x); msgs.sort { $0.ts < $1.ts } }
            }
        case "ack":
            if let cid = o["cid"] as? String, let id = o["id"] as? String, let ts = o["ts"] as? Double {
                if let i = msgs.firstIndex(where: { $0.id == cid }) {
                    msgs[i] = Msg(id: id, from: msgs[i].from, to: msgs[i].to, text: msgs[i].text, ts: ts, kind: msgs[i].kind)
                }
            }
        case "recall":
            if let id = o["id"] as? String, let i = msgs.firstIndex(where: { $0.id == id }) { msgs[i].recalled = true }
        case "err":
            if let m = o["msg"] as? String { print("[ws err] " + m) }
        default:
            break
        }
    }

    private func applyPeople(_ list: [[String: Any]]) {
        for p in list {
            guard let id = p["id"] as? String else { continue }
            people[id] = Person(id: id,
                                name: (p["name"] as? String) ?? id,
                                online: (p["online"] as? Bool) ?? false,
                                remark: (p["remark"] as? String) ?? "",
                                account: (p["account"] as? String) ?? "",
                                avatar: (p["avatar"] as? String) ?? "")
        }
    }

    private func applySocial(_ o: [String: Any]) {
        if let f = o["friends"] as? [[String: Any]] {
            friends = f.compactMap { p in
                guard let id = p["id"] as? String else { return nil }
                let person = Person(id: id,
                                    name: (p["name"] as? String) ?? id,
                                    online: (p["online"] as? Bool) ?? false,
                                    remark: (p["remark"] as? String) ?? "",
                                    account: (p["account"] as? String) ?? "",
                                    avatar: (p["avatar"] as? String) ?? "")
                people[id] = person
                return person
            }.sorted { $0.name < $1.name }
        }
        if let g = o["groups"] as? [[String: Any]] {
            groups = g.compactMap { x in
                guard let id = x["id"] as? String else { return nil }
                return Group(id: id, name: (x["name"] as? String) ?? "群聊",
                             members: (x["members"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? [])
            }
        }
        if let a = o["allIn"] as? Bool { allIn = a }
    }

    private func msgOf(_ m: [String: Any]) -> Msg? {
        guard let id = m["id"] as? String, let from = m["from"] as? String, let to = m["to"] as? String else { return nil }
        return Msg(id: id, from: from, to: to,
                   text: (m["text"] as? String) ?? "",
                   ts: (m["ts"] as? Double) ?? 0,
                   kind: (m["kind"] as? String) ?? "text",
                   recalled: (m["recalled"] as? Bool) ?? false,
                   read: (m["read"] as? Int) ?? 0)
    }

    /* ---------- 发消息 ---------- */
    func send(to: String, text: String) {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, !token.isEmpty else { return }
        let cid = "c" + String(Int(Date().timeIntervalSince1970 * 1000))
        msgs.append(Msg(id: cid, from: meUserId, to: to, text: s, ts: Date().timeIntervalSince1970 * 1000))
        raw(["t": "send", to: to, text: s, cid: cid])
    }

    var meUserId = ""      // 服务端给的 userId（authed 里没有，用 people 找自己）

    /* ---------- 会话列表（从消息算出来） ---------- */
    var convs: [Conv] {
        var map: [String: Conv] = [:]
        for m in msgs {
            let isGroup = m.to == "all" || m.to.hasPrefix("g")
            let cid = isGroup ? m.to : (m.from == meUserId ? m.to : m.from)
            guard !cid.isEmpty else { continue }
            var c = map[cid] ?? Conv(id: cid, name: name(of: cid, isGroup: isGroup), text: "",
                                     ts: 0, unread: 0, isGroup: isGroup, online: false)
            if m.ts >= c.ts {
                c.ts = m.ts
                c.text = m.recalled ? "撤回了一条消息" : (m.kind == "image" ? "[图片]" : (m.kind == "file" ? "[文件]" : m.text))
            }
            if m.from != meUserId, m.ts > (lastRead[cid] ?? 0) { c.unread += 1 }
            c.online = people[cid]?.online ?? false
            c.name = name(of: cid, isGroup: isGroup)
            map[cid] = c
        }
        return map.values.sorted { $0.ts > $1.ts }
    }

    func name(of id: String, isGroup: Bool) -> String {
        if id == "all" { return "全员群" }
        if isGroup || id.hasPrefix("g") { return groups.first(where: { $0.id == id })?.name ?? "群聊" }
        if id == meUserId { return meName.isEmpty ? "我" : meName }
        let p = people[id]
        return (p?.display).flatMap { $0.isEmpty ? nil : $0 } ?? p?.name ?? id
    }

    func thread(_ cid: String) -> [Msg] {
        let isGroup = cid == "all" || cid.hasPrefix("g")
        return msgs.filter { m in
            if isGroup { return m.to == cid }
            return (m.from == cid && m.to == meUserId) || (m.from == meUserId && m.to == cid)
        }
    }

    func markRead(_ cid: String) {
        lastRead[cid] = Date().timeIntervalSince1970 * 1000
        UserDefaults.standard.set(lastRead, forKey: "bbji_lastread")
    }

    private func loadRead() {
        if let d = UserDefaults.standard.dictionary(forKey: "bbji_lastread") as? [String: Double] { lastRead = d }
    }
}

/* 时间显示：今天 HH:mm / 昨天 / 月-日 */
func timeText(_ ts: Double) -> String {
    let d = Date(timeIntervalSince1970: ts / 1000)
    let f = DateFormatter()
    if Calendar.current.isDateInToday(d) { f.dateFormat = "HH:mm" }
    else if Calendar.current.isDateInYesterday(d) { return "昨天" }
    else { f.dateFormat = "MM-dd" }
    return f.string(from: d)
}
