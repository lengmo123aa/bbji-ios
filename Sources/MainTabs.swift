import SwiftUI
import PhotosUI

/* ==================================================================
   0.0.3：主界面全部自绘 —— 照 v5 效果图（大标题 / 搜索框 / 无分割线行 /
   自定义标签栏 / 自定义聊天气泡），不再用系统的 List、导航栏、TabView。
   ================================================================== */

struct MainTabs: View {
    @EnvironmentObject var session: Session
    @StateObject private var store = Store()
    @State private var sel = 0

    var body: some View {
        NavigationView {
            ZStack {
                AppBg().ignoresSafeArea()
                VStack(spacing: 0) {
                    switch sel {
                    case 0: ChatListPage().environmentObject(store)
                    case 1: ContactsPage().environmentObject(store).environmentObject(session)
                    default: MePage().environmentObject(store).environmentObject(session)
                    }
                    DZTabBar(sel: $sel)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear { store.connect(token: session.token) { session.logout() } }
        .onDisappear { store.disconnect() }
    }
}

/* ==================== 06 消息列表 ==================== */
struct ChatListPage: View {
    @EnvironmentObject var store: Store
    var body: some View {
        VStack(spacing: 0) {
            TopTitle(text: "消息") {
                NavigationLink(destination: AddFriendView().environmentObject(store).navigationBarHidden(false)) {
                    Image(systemName: "plus.circle").font(.system(size: 22)).foregroundColor(T.blue)
                }
            }
            SearchBar(placeholder: "搜索聊天、联系人、消息")
            if store.convs.isEmpty {
                VStack(spacing: 8) {
                    Text(store.connected ? "还没有聊天" : "连接中…")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(T.ink)
                    Text("在电脑端先跟人聊两句，这边就会出现")
                        .font(.system(size: 12)).foregroundColor(T.sec2)
                }
                .frame(maxWidth: .infinity).padding(.top, 90)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.convs) { c in
                            NavigationLink(destination: ChatScreen(cid: c.id, isGroup: c.isGroup)
                                .environmentObject(store)) {
                                ConvRow(c: c)
                            }
                            .buttonStyle(.plain)
                            .swipeActionsCompat(c: c, store: store)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

/// 一行会话（效果图 .li：padding 4/16、头像 46、名字 14/600、预览 12.5、时间 11、红点 18）
private struct ConvRow: View {
    let c: Conv
    var body: some View {
        HStack(spacing: 11) {
            Ava(name: c.name, size: 46, online: c.isGroup ? nil : c.online)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if c.pinned { Image(systemName: "pin.fill").font(.system(size: 10)).foregroundColor(T.blue) }
                    Text(c.name).font(.system(size: 14, weight: .semibold)).kerning(-0.25).foregroundColor(T.ink)
                }
                Text(c.text).font(.system(size: 12.5)).foregroundColor(T.sec2).lineLimit(1)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 6) {
                Text(timeText(c.ts)).font(.system(size: 11)).foregroundColor(T.ter2)
                if c.muted {
                    Image(systemName: "bell.slash.fill").font(.system(size: 11)).foregroundColor(T.ter2)
                } else if c.unread > 0 {
                    BadgeNum(n: c.unread)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// contextMenu + swipe 在自定义行里也能用（自己拼一个，避免用系统 List）
private extension View {
    func swipeActionsCompat(c: Conv, store: Store) -> some View {
        self
            .contextMenu {
                Button { store.markRead(c.id) } label: { Label("标为已读", systemImage: "checkmark.circle") }
                Button { store.togglePin(c.id) } label: {
                    Label(store.pinned.contains(c.id) ? "取消置顶" : "置顶聊天", systemImage: "pin")
                }
                Button { store.toggleMute(c.id) } label: {
                    Label(store.muted.contains(c.id) ? "取消免打扰" : "消息免打扰", systemImage: "bell.slash")
                }
                Button(role: .destructive) { store.hideConv(c.id) } label: {
                    Label("删除聊天", systemImage: "trash")
                }
            }
    }
}

/* ==================== 12 单聊 / 群聊 ==================== */
struct ChatScreen: View {
    @EnvironmentObject var store: Store
    let cid: String
    let isGroup: Bool
    @Environment(\.presentationMode) private var pm
    @State private var draft = ""
    @State private var pick: PhotosPickerItem? = nil
    @State private var sending = false

    var body: some View {
        VStack(spacing: 0) {
            /* 自绘顶栏（效果图 .navbar: 高 42 + 头像 30 + 名字 14.5） */
            HStack(spacing: 8) {
                Button { pm.wrappedValue.dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                        .foregroundColor(T.blue).frame(width: 22, height: 30)
                }
                Ava(name: store.name(of: cid, isGroup: isGroup), size: 30,
                    online: isGroup ? nil : (store.people[cid]?.online ?? false))
                VStack(alignment: .leading, spacing: 1) {
                    Text(store.name(of: cid, isGroup: isGroup))
                        .font(.system(size: 14.5, weight: .semibold)).kerning(-0.2).foregroundColor(T.ink)
                    if !isGroup {
                        Text(store.people[cid]?.online == true ? "在线" : "不在线")
                            .font(.system(size: 10)).foregroundColor(T.sec2)
                    }
                }
                Spacer()
                if isGroup {
                    NavigationLink(destination: GroupSettingsView(gid: cid).environmentObject(store)
                        .navigationBarHidden(false)) {
                        Image(systemName: "ellipsis").font(.system(size: 17)).foregroundColor(T.blue)
                    }
                } else {
                    Image(systemName: "phone").font(.system(size: 16)).foregroundColor(T.blue)
                        .padding(.trailing, 12)
                    Image(systemName: "video").font(.system(size: 16)).foregroundColor(T.blue)
                }
            }
            .padding(.horizontal, 14).frame(height: 42)
            .background(Color.white.opacity(0.5))

            ScrollViewReader { sp in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.thread(cid)) { m in
                            Bubble(m: m, mine: m.from == store.meUserId,
                                   peer: store.name(of: cid, isGroup: isGroup)).environmentObject(store)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                }
                .onChange(of: store.thread(cid).count) { _ in
                    if let last = store.thread(cid).last { withAnimation { sp.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            /* 输入条（效果图 .cbar：麦克风 + 圆角输入框 + 表情 + 加号） */
            HStack(spacing: 9) {
                Image(systemName: "mic").font(.system(size: 21)).foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                PhotosPicker(selection: $pick, matching: .images) {
                    Image(systemName: sending ? "hourglass" : "photo.on.rectangle")
                        .font(.system(size: 20)).foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                }
                TextField("输入消息", text: $draft)
                    .font(.system(size: 12.5))
                    .padding(.horizontal, 12).frame(height: 36)
                    .background(Color.white.opacity(0.85))
                    .clipShape(Capsule())
                Button {
                    store.send(to: cid, text: draft); draft = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 28))
                        .foregroundColor(draft.trimmingCharacters(in: .whitespaces).isEmpty ? T.tabIdle : T.blue)
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 14).padding(.top, 9).padding(.bottom, 18)
            .background(Color.white.opacity(0.55))
        }
        .background(AppBg().ignoresSafeArea())
        .onAppear { store.markRead(cid) }
        .onChange(of: pick) { item in
            guard let item else { return }
            sending = true
            Task {
                if let d = try? await item.loadTransferable(type: Data.self) {
                    await store.sendImage(to: cid, data: d, name: "IMG_\(Int(Date().timeIntervalSince1970)).jpg")
                }
                sending = false
                pick = nil
            }
        }
    }
}

/// 气泡（效果图 .b：max-width 186 / padding 9-12 / 圆角 16 / 12.5px / 行高 1.45）
private struct Bubble: View {
    let m: Msg
    let mine: Bool
    let peer: String
    @EnvironmentObject var store: Store

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if mine { Spacer(minLength: 40) }
            if !mine { Ava(name: peer, size: 30) }
            Group {
                if m.kind == "image", let fid = m.fileId, let u = store.fileURL(fid) {
                    AsyncImage(url: u) { ph in
                        if let img = ph.image {
                            img.resizable().scaledToFill()
                                .frame(maxWidth: 186, maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.7))
                                .frame(width: 150, height: 150).overlay(ProgressView())
                        }
                    }
                } else {
                    Text(m.recalled ? "撤回了一条消息" : (m.text.isEmpty ? "[\(m.kind)]" : m.text))
                        .font(.system(size: 12.5))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)      // ← 关键：别把文字挤成一列
                        .foregroundColor(mine ? .white : T.ink)
                        .frame(maxWidth: 186, alignment: .leading)
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(mine ? AnyView(T.gradBlue) : AnyView(Color.white.opacity(0.86)))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .opacity(m.recalled ? 0.6 : 1)
                }
            }
            .contextMenu {
                Button { UIPasteboard.general.string = m.text } label: { Label("复制", systemImage: "doc.on.doc") }
                if mine && !m.recalled && Date().timeIntervalSince1970 * 1000 - m.ts < 10 * 60 * 1000 {
                    Button(role: .destructive) { store.recall(m.id) } label: {
                        Label("撤回", systemImage: "arrow.uturn.backward")
                    }
                }
            }
            if !mine { Spacer(minLength: 40) }
        }
    }
}

/* ==================== 09 通讯录 ==================== */
struct ContactsPage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var session: Session
    private var pendingCount: Int { store.reqs.filter { !$0.outgoing && $0.state == "pending" }.count }

    var body: some View {
        VStack(spacing: 0) {
            TopTitle(text: "通讯录") {
                NavigationLink(destination: AddFriendView().environmentObject(store).navigationBarHidden(false)) {
                    Image(systemName: "plus.circle").font(.system(size: 22)).foregroundColor(T.blue)
                }
            }
            SearchBar(placeholder: "搜索联系人")
            ScrollView {
                VStack(spacing: 0) {
                    /* 新的朋友 / 群聊（卡片） */
                    VStack(spacing: 0) {
                        NavigationLink(destination: NewFriendsView().environmentObject(store).navigationBarHidden(false)) {
                            IconRow(icon: "person.badge.plus", color: Color(red: 0.36, green: 0.60, blue: 0.98),
                                    title: "新的朋友", trailing: pendingCount > 0 ? "\(pendingCount)" : "")
                        }.buttonStyle(.plain)
                        ForEach(store.groups) { g in
                            NavigationLink(destination: ChatScreen(cid: g.id, isGroup: true)
                                .environmentObject(store)) {
                                IconRow(icon: "bubble.left.and.bubble.right.fill",
                                        color: Color(red: 0.30, green: 0.78, blue: 0.35),
                                        title: g.name, trailing: "\(g.members.count) 人")
                            }.buttonStyle(.plain)
                        }
                    }
                    .glassCard(24).padding(.horizontal, 14).padding(.bottom, 14)

                    HStack {
                        Text("好友 · \(store.friends.count)")
                            .font(.system(size: 11)).foregroundColor(T.sec2)
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.bottom, 6)

                    VStack(spacing: 0) {
                        ForEach(store.friends) { f in
                            NavigationLink(destination: FriendProfileView(pid: f.id)
                                .environmentObject(store).navigationBarHidden(false)) {
                                HStack(spacing: 11) {
                                    Ava(name: f.display, size: 40, online: f.online, img: f.avatar)
                                    Text(f.display).font(.system(size: 13.5)).foregroundColor(T.ink)
                                    Spacer()
                                }
                                .padding(.horizontal, 16).frame(height: 54)
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                        if store.friends.isEmpty {
                            Text("还没有好友").font(.system(size: 12.5)).foregroundColor(T.sec2)
                                .padding(.vertical, 14)
                        }
                    }
                    .glassCard(24).padding(.horizontal, 14)
                }
                .padding(.bottom, 16)
            }
        }
    }
}

/// 通讯录那种「小圆角图标 + 标题 + 右边小字」的行
struct IconRow: View {
    let icon: String
    let color: Color
    let title: String
    var trailing: String = ""
    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .top, endPoint: .bottom))
                    .frame(width: 22, height: 22)
                Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
            }
            Text(title).font(.system(size: 13.5)).foregroundColor(T.ink)
            Spacer()
            if !trailing.isEmpty {
                Text(trailing).font(.system(size: 11.5)).foregroundColor(T.sec2)
            }
        }
        .padding(.horizontal, 16).frame(height: 50)
        .contentShape(Rectangle())
    }
}

/* ==================== 11 我 ==================== */
struct MePage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var session: Session
    var body: some View {
        VStack(spacing: 0) {
            TopTitle("我")
            ScrollView {
                VStack(spacing: 0) {
                    /* 资料卡：头像在上、名字和号在下面居中（用户 2026-10-07 定的） */
                    VStack(spacing: 0) {
                        Ava(name: session.myName.isEmpty ? "我" : session.myName, size: 84, img: store.myAvatar)
                        Text(session.myName.isEmpty ? "—" : session.myName)
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(T.ink)
                            .padding(.top, 11)
                        Text("BB鸡号 \(session.myId)").font(.system(size: 11)).foregroundColor(T.sec2)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
                    .glassCard(24).padding(.horizontal, 14).padding(.bottom, 14)

                    VStack(spacing: 0) {
                        NavigationLink(destination: MyProfileView().environmentObject(store)
                            .environmentObject(session).navigationBarHidden(false)) {
                            IconRow(icon: "person.text.rectangle", color: T.blue, title: "我的资料")
                        }.buttonStyle(.plain)
                        NavigationLink(destination: WebShell().navigationBarHidden(false).navigationBarTitle("设计稿")) {
                            IconRow(icon: "square.grid.2x2", color: Color(red: 0.98, green: 0.62, blue: 0.24),
                                    title: "设计稿（v5 · 61 屏）")
                        }.buttonStyle(.plain)
                        HStack(spacing: 11) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(LinearGradient(colors: [Color(red: 0.68, green: 0.50, blue: 0.98),
                                                                  Color(red: 0.55, green: 0.36, blue: 0.95)],
                                                         startPoint: .top, endPoint: .bottom))
                                    .frame(width: 22, height: 22)
                                Image(systemName: "gearshape.fill").font(.system(size: 11)).foregroundColor(.white)
                            }
                            Text("连接状态").font(.system(size: 13.5)).foregroundColor(T.ink)
                            Spacer()
                            Text(store.connected ? "已连上服务器" : "重连中…")
                                .font(.system(size: 11.5)).foregroundColor(store.connected ? T.green : T.sec2)
                        }
                        .padding(.horizontal, 16).frame(height: 50)
                    }
                    .glassCard(24).padding(.horizontal, 14).padding(.bottom, 14)

                    VStack(spacing: 0) {
                        Button {
                            store.disconnect(); session.logout()
                        } label: {
                            Text("退出登录").font(.system(size: 13.5)).foregroundColor(T.red)
                                .frame(maxWidth: .infinity).frame(height: 50)
                        }
                    }
                    .glassCard(24).padding(.horizontal, 14)
                }
                .padding(.bottom, 16)
            }
        }
    }
}


