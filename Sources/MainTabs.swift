import SwiftUI

/// M1 第一块：消息 / 通讯录 / 我 —— 数据全是真的（走 wss://bbji.xkmd.cn）。
struct MainTabs: View {
    @EnvironmentObject var session: Session
    @StateObject private var store = Store()

    var body: some View {
        TabView {
            ChatListView().environmentObject(store)
                .tabItem { Label("消息", systemImage: "bubble.left.and.bubble.right.fill") }
                .badge(store.convs.reduce(0) { $0 + $1.unread })
            ContactsView().environmentObject(store)
                .tabItem { Label("通讯录", systemImage: "person.2.fill") }
            MeView().environmentObject(store).environmentObject(session)
                .tabItem { Label("我", systemImage: "person.crop.circle.fill") }
        }
        .accentColor(T.blue)
        .onAppear { store.connect(token: session.token) { session.logout() } }
        .onDisappear { store.disconnect() }
    }
}

/* ==================== 头像（画个渐变圆 + 首字，在线加绿点、离线变灰，跟设计稿一样） ==================== */
struct Ava: View {
    let name: String
    var size: CGFloat = 40
    var online: Bool? = nil
    private var hue: Double {
        var h = 0
        for u in name.unicodeScalars { h = (h &* 31 &+ Int(u.value)) % 360 }
        return Double(h) / 360
    }
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hue: hue, saturation: 0.40, brightness: 0.99),
                                                      Color(hue: hue, saturation: 0.62, brightness: 0.84)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(name.prefix(1))).font(.system(size: size * 0.4, weight: .semibold)).foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .saturation(online == false ? 0 : 1)
            .opacity(online == false ? 0.5 : 1)
            if online == true {
                Circle().fill(T.green).frame(width: size * 0.3, height: size * 0.3)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.6))
            }
        }
        .frame(width: size, height: size)
    }
}

/* ==================== 06 消息列表 ==================== */
struct ChatListView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        NavigationView {
            ZStack {
                AppBg().ignoresSafeArea()
                if store.convs.isEmpty {
                    VStack(spacing: 8) {
                        Text(store.connected ? "还没有聊天" : "连接中…")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(T.ink)
                        Text("在电脑端先跟人聊两句，这边就会出现")
                            .font(.system(size: 12)).foregroundColor(T.gray)
                    }
                } else {
                    List {
                        ForEach(store.convs) { c in
                            NavigationLink(destination: ChatScreen(cid: c.id, isGroup: c.isGroup).environmentObject(store)) {
                                ConRow(c: c)
                            }
                            .listRowBackground(Color.white.opacity(0.6))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("消息")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(store.connected ? "在线" : "重连中…")
                        .font(.system(size: 11)).foregroundColor(store.connected ? T.green : T.gray)
                }
            }
        }
    }
}

private struct ConRow: View {
    let c: Conv
    var body: some View {
        HStack(spacing: 11) {
            Ava(name: c.name, size: 44, online: c.isGroup ? nil : c.online)
            VStack(alignment: .leading, spacing: 3) {
                Text(c.name).font(.system(size: 14, weight: .semibold)).foregroundColor(T.ink)
                Text(c.text).font(.system(size: 12)).foregroundColor(T.gray).lineLimit(1)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 6) {
                Text(timeText(c.ts)).font(.system(size: 11)).foregroundColor(Color(red: 0.72, green: 0.75, blue: 0.79))
                if c.unread > 0 {
                    Text("\(c.unread)")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(T.red))
                }
            }
        }
        .padding(.vertical, 5)
    }
}

/* ==================== 12 单聊 / 群聊 ==================== */
struct ChatScreen: View {
    @EnvironmentObject var store: Store
    let cid: String
    let isGroup: Bool
    @State private var draft = ""

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollViewReader { sp in
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(store.thread(cid)) { m in
                                Bubble(m: m, mine: m.from == store.meUserId)
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                    }
                    .onChange(of: store.thread(cid).count) { _ in
                        if let last = store.thread(cid).last { withAnimation { sp.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
                HStack(spacing: 8) {
                    TextField("输入消息", text: $draft)
                        .font(.system(size: 13.5))
                        .padding(.horizontal, 12).frame(height: 38)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Capsule())
                    Button {
                        store.send(to: cid, text: draft)
                        draft = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundColor(T.blue)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.6))
            }
        }
        .navigationTitle(store.name(of: cid, isGroup: isGroup))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markRead(cid) }
    }
}

private struct Bubble: View {
    let m: Msg
    let mine: Bool
    var body: some View {
        HStack {
            if mine { Spacer(minLength: 40) }
            Text(m.recalled ? "撤回了一条消息" : (m.text.isEmpty ? "[\(m.kind)]" : m.text))
                .font(.system(size: 13.5))
                .foregroundColor(mine ? .white : T.ink)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(mine
                            ? AnyView(LinearGradient(colors: [T.blueLight, T.blue], startPoint: .top, endPoint: .bottom))
                            : AnyView(Color.white.opacity(0.92)))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(m.recalled ? 0.6 : 1)
            if !mine { Spacer(minLength: 40) }
        }
    }
}

/* ==================== 09 通讯录 ==================== */
struct ContactsView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        NavigationView {
            ZStack {
                AppBg().ignoresSafeArea()
                List {
                    Section {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill").foregroundColor(T.blue)
                            Text("群聊 · \(store.groups.count) 个")
                            Spacer()
                            Text(store.allIn ? "已加入全员群" : "未加入全员群")
                                .font(.system(size: 11.5)).foregroundColor(T.gray)
                        }
                    }
                    Section(header: Text("好友 · \(store.friends.count)")) {
                        if store.friends.isEmpty {
                            Text("还没有好友").font(.system(size: 12.5)).foregroundColor(T.gray)
                        }
                        ForEach(store.friends) { f in
                            HStack(spacing: 10) {
                                Ava(name: f.display, size: 34, online: f.online)
                                Text(f.display).font(.system(size: 13.5))
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("通讯录")
        }
    }
}

/* ==================== 11 我 ==================== */
struct MeView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var session: Session
    var body: some View {
        NavigationView {
            ZStack {
                AppBg().ignoresSafeArea()
                List {
                    Section {
                        VStack(spacing: 10) {
                            Ava(name: session.myName.isEmpty ? "我" : session.myName, size: 84)
                            Text(session.myName.isEmpty ? "—" : session.myName)
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(T.ink)
                            Text("BB鸡号 \(session.myId)").font(.system(size: 11)).foregroundColor(T.gray)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    Section {
                        NavigationLink("设计稿（v5 · 61 屏）") { WebShell() }
                        HStack {
                            Text("连接状态")
                            Spacer()
                            Text(store.connected ? "已连上服务器" : "重连中…")
                                .font(.system(size: 12)).foregroundColor(store.connected ? T.green : T.gray)
                        }
                    }
                    Section {
                        Button("退出登录", role: .destructive) {
                            store.disconnect()
                            session.logout()
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("我")
        }
    }
}
