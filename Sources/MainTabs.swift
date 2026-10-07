import SwiftUI
import UIKit
import PhotosUI

/* ==================================================================
   主界面（原生精修 / 重塑）—— 第二轮
   ⚠️ 关键认知（2026-10-07 定了）：效果图那套 HTML 是按 **270pt 宽**画框画的，
      真机 iPhone 393pt → 效果图的数值搬到手机上会"小一圈、扁一圈"。
      所以凡是"从效果图抄来的"数（字号/头像/行高/圆角/间距），一律 ×T.k（≈1.455）。
      只有 iOS 自己的东西（安全区、原生手势）不乘。
   本轮：全局放大 + 聊天贴底 + 长按自绘菜单(引用/复制/转发/撤回) + 引用发送与显示
        + 我页 BB鸡号修对 + 通讯录加「群聊」行。
   ================================================================== */

/// 列表滚动量（用来做"内容滚到栏下面才出现毛玻璃"的贴边效果）
struct OffKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct MainTabs: View {
    @EnvironmentObject var session: Session
    @StateObject private var store = Store()
    @State private var sel = 0

    var body: some View {
        NavigationView {
            ZStack {
                AppBg()
                VStack(spacing: 0) {
                    ZStack {
                        ChatListPage()
                            .opacity(sel == 0 ? 1 : 0)
                            .offset(y: sel == 0 ? 0 : 8)
                            .allowsHitTesting(sel == 0)
                        ContactsPage()
                            .environmentObject(session)
                            .opacity(sel == 1 ? 1 : 0)
                            .offset(y: sel == 1 ? 0 : 8)
                            .allowsHitTesting(sel == 1)
                        MePage()
                            .environmentObject(session)
                            .opacity(sel == 2 ? 1 : 0)
                            .offset(y: sel == 2 ? 0 : 8)
                            .allowsHitTesting(sel == 2)
                    }
                    .environmentObject(store)
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
    @State private var off: CGFloat = 0
    @State private var openRow: String? = nil
    @State private var q = ""

    private var list: [Conv] {
        let all = store.convs
        let s = q.trimmingCharacters(in: .whitespaces)
        if s.isEmpty { return all }
        return all.filter { $0.name.contains(s) || $0.text.contains(s) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if list.isEmpty { empty } else { rows }
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                Text("消息")
                    .font(.system(size: 25 * T.k, weight: .bold))
                    .kerning(-0.9 * T.k)
                    .foregroundColor(T.ink)
                Spacer(minLength: 0)
                NavigationLink(destination: AddFriendView().environmentObject(store).navigationBarHidden(false)) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22 * T.k, weight: .light))
                        .foregroundColor(T.blue)
                }
                .buttonStyle(PressStyle(scale: 0.88))
            }
            .padding(.horizontal, 18 * T.k).padding(.top, 2).padding(.bottom, 12 * T.k)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13 * T.k, weight: .medium))
                    .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.68))
                ZStack(alignment: .leading) {
                    if q.isEmpty {
                        Text("搜索聊天、联系人、消息")
                            .font(.system(size: 12 * T.k)).foregroundColor(T.hint)
                    }
                    TextField("", text: $q)
                        .font(.system(size: 12 * T.k))
                        .foregroundColor(T.ink)
                        .tint(T.blue)
                        .submitLabel(.search)
                        .disableAutocorrection(true)
                }
                if !q.isEmpty {
                    Button { q = ""; H.tap() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13 * T.k))
                            .foregroundColor(Color(red: 0.72, green: 0.76, blue: 0.81))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15).frame(height: 34 * T.k)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.60), lineWidth: 0.5))
            .shadow(color: Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.04), radius: 4, y: 2)
            .padding(.horizontal, 14 * T.k).padding(.bottom, 10 * T.k)
        }
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color.white.opacity(0.34))
            }
            .opacity(min(1, max(0, off / 26)))
            .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(T.sep).frame(height: 0.5).opacity(min(1, max(0, off / 26)))
        }
    }

    private var rows: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Color.clear.frame(height: 0)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: OffKey.self,
                                               value: -g.frame(in: .named("chatlist")).minY)
                    })
                ForEach(list) { c in
                    row(c)
                }
            }
            .padding(.bottom, 18)
        }
        .coordinateSpace(name: "chatlist")
        .onPreferenceChange(OffKey.self) { v in off = v }
        .scrollDismissesKeyboard(.interactively)
    }

    private func row(_ c: Conv) -> some View {
        SwipeRow(id: c.id, openID: $openRow, height: 76,
                 tint: c.pinned ? T.pinBg : Color.clear,
                 actions: [
                    SwipeAct(title: "置顶", bg: AnyView(T.gradSwipeGray)) { store.togglePin(c.id) },
                    SwipeAct(title: "免打扰", bg: AnyView(T.gradOrange)) { store.toggleMute(c.id) },
                    SwipeAct(title: "删除", bg: AnyView(Color(red: 1.0, green: 0.231, blue: 0.188))) { store.hideConv(c.id) },
                 ]) {
            NavigationLink(destination: ChatScreen(cid: c.id, isGroup: c.isGroup).environmentObject(store)) {
                ConvRow(c: c, avatar: store.avatarId(c.id, isGroup: c.isGroup))
            }
            .buttonStyle(PressStyle(scale: 0.985))
        }
        .contextMenu {
            Button { store.markRead(c.id); H.tap() } label: { Label("标为已读", systemImage: "checkmark.circle") }
            Button { store.togglePin(c.id); H.tap() } label: {
                Label(store.pinned.contains(c.id) ? "取消置顶" : "置顶聊天", systemImage: "pin")
            }
            Button { store.toggleMute(c.id); H.tap() } label: {
                Label(store.muted.contains(c.id) ? "取消免打扰" : "消息免打扰", systemImage: "bell.slash")
            }
            Button(role: .destructive) { store.hideConv(c.id); H.warn() } label: {
                Label("删除聊天", systemImage: "trash")
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Text(q.isEmpty ? (store.connected ? "还没有聊天" : "连接中…") : "没找到")
                .font(.system(size: 22, weight: .semibold)).foregroundColor(T.ink)
            Text(q.isEmpty ? "在电脑端先跟人聊两句，这边就会出现" : "换个词试试")
                .font(.system(size: 17)).foregroundColor(T.sec2)
        }
        .frame(maxWidth: .infinity).padding(.top, 120)
        Spacer(minLength: 0)
    }
}

/// 一行会话（×k 之后：头像 64 / 名字 20 / 预览 18 / 时间 15 / 行高 76）
private struct ConvRow: View {
    let c: Conv
    var avatar: String = ""
    var body: some View {
        HStack(spacing: 16) {
            Ava(name: c.name, size: 64, online: c.isGroup ? nil : c.online, img: avatar)
            VStack(alignment: .leading, spacing: 4) {
                Text(c.name)
                    .font(.system(size: 20, weight: .semibold))
                    .kerning(-0.36)
                    .foregroundColor(T.ink)
                    .lineLimit(1)
                Text(c.text)
                    .font(.system(size: 18))
                    .foregroundColor(T.sec2)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 9) {
                Text(timeText(c.ts)).font(.system(size: 15)).foregroundColor(T.ter2)
                if c.muted {
                    Image(systemName: "bell.slash.fill").font(.system(size: 15)).foregroundColor(T.ter2)
                } else if c.unread > 0 {
                    BadgeNum(n: c.unread)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 6)
        .frame(height: 76)
        .contentShape(Rectangle())
    }
}

/* ==================== 左滑（自绘） ==================== */
struct SwipeAct: Identifiable {
    let id = UUID()
    let title: String
    let bg: AnyView
    let action: () -> Void
}

struct SwipeRow<Content: View>: View {
    let id: String
    @Binding var openID: String?
    var height: CGFloat = 76
    var tint: Color = .clear
    let actions: [SwipeAct]
    @ViewBuilder var content: () -> Content

    @State private var dx: CGFloat = 0
    @State private var dragging = false
    @State private var crossed = false

    private var width: CGFloat { CGFloat(actions.count) * 80 }
    private var reveal: CGFloat { max(0, -dx) }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                ForEach(actions) { a in
                    Button {
                        H.tap(.medium)
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) { dx = 0 }
                        openID = nil
                        a.action()
                    } label: {
                        a.bg
                            .frame(width: 80, height: height)
                            .overlay(Text(a.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: width, height: height, alignment: .trailing)
            .frame(width: reveal, height: height, alignment: .trailing)
            .clipped()

            content()
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        tint
                        T.rowSolid.opacity(min(1, reveal / 14))
                    }
                )
                .offset(x: dx)
        }
        .frame(height: height)
        .contentShape(Rectangle())
        .simultaneousGesture(drag)
        .onChange(of: openID) { v in
            if v != id {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) { dx = 0 }
            }
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { v in
                let w = v.translation.width, h = v.translation.height
                if !dragging {
                    guard abs(w) > abs(h) * 1.25, abs(w) > 4 else { return }
                    dragging = true
                }
                let base: CGFloat = (openID == id) ? -width : 0
                dx = max(-width - 18, min(0, base + w))
                let nowCrossed = reveal > width * 0.45
                if nowCrossed != crossed {
                    crossed = nowCrossed
                    H.tap(.light)
                }
            }
            .onEnded { v in
                guard dragging else { return }
                dragging = false
                let fling = v.predictedEndTranslation.width < -40
                let open = reveal > width * 0.40 || (fling && v.translation.width < -16)
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    dx = open ? -width : 0
                }
                openID = open ? id : nil
                crossed = false
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
    @State private var off: CGFloat = 0
    @State private var edgeX: CGFloat = 0
    @State private var viewer: Msg? = nil
    @State private var vDrag: CGFloat = 0
    @State private var tipText = ""
    @State private var quoting: Quote? = nil        // 正在引用的那条
    @State private var menuFor: Msg? = nil          // 长按弹出的菜单
    @State private var forwardMsg: Msg? = nil       // 转发选人

    private var thread: [Msg] { store.thread(cid) }
    private var peer: String { store.name(of: cid, isGroup: isGroup) }
    private var peerAv: String { store.avatarId(cid, isGroup: isGroup) }
    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppBg()
            VStack(spacing: 0) {
                navbar
                msgs
                inputBar
            }
            .offset(x: edgeX)
            .simultaneousGesture(backDrag)

            if let v = viewer { viewerLayer(v) }
            if let mm = menuFor { menuLayer(mm) }
            if forwardMsg != nil { forwardLayer }
            if !tipText.isEmpty { toastLayer }
        }
        .navigationBarHidden(true)
        .onAppear { store.markRead(cid) }
        .onChange(of: pick) { item in
            guard let item else { return }
            sending = true
            H.tap()
            Task {
                if let d = try? await item.loadTransferable(type: Data.self) {
                    await store.sendImage(to: cid, data: d,
                                          name: "IMG_\(Int(Date().timeIntervalSince1970)).jpg")
                    H.ok()
                }
                sending = false
                pick = nil
            }
        }
    }

    /* ---------- 顶栏（.navbar 42 ×k ≈ 58 / 头像 30→40 / 名字 14.5→20） ---------- */
    private var navbar: some View {
        HStack(spacing: 12) {
            Button {
                H.tap()
                pm.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(T.blue)
                    .frame(width: 24, height: 40, alignment: .leading)
            }
            .buttonStyle(PressStyle(scale: 0.85))

            Ava(name: peer, size: 40,
                online: isGroup ? nil : (store.people[cid]?.online ?? false),
                img: peerAv)

            Text(peer)
                .font(.system(size: 20, weight: .semibold))
                .kerning(-0.29)
                .foregroundColor(T.ink)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 19) {
                if isGroup {
                    NavigationLink(destination: GroupSettingsView(gid: cid)
                        .environmentObject(store).navigationBarHidden(false)) {
                        navIcon("ellipsis")
                    }
                    .buttonStyle(PressStyle(scale: 0.88))
                } else {
                    Button { tip("语音通话下一轮做") } label: { navIcon("phone") }
                        .buttonStyle(PressStyle(scale: 0.88))
                    Button { tip("视频通话下一轮做") } label: { navIcon("video") }
                        .buttonStyle(PressStyle(scale: 0.88))
                    Button { tip("聊天设置下一轮做") } label: { navIcon("ellipsis") }
                        .buttonStyle(PressStyle(scale: 0.88))
                }
            }
        }
        .padding(.horizontal, 14 * T.k).frame(height: 58)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color.white.opacity(0.45))
            }
            .opacity(min(1, max(0, off / 26)))
            .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(T.sep).frame(height: 0.5).opacity(min(1, max(0, off / 26)))
        }
    }

    private func navIcon(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 24, weight: .regular)).foregroundColor(T.blue)
    }

    /* ---------- 消息区（.chat ×k；少消息时贴着输入框往下靠，别顶在上面留一大片空） ---------- */
    private var msgs: some View {
        GeometryReader { geo in
            ScrollViewReader { sp in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Color.clear.frame(height: 0)
                            .background(GeometryReader { g in
                                Color.clear.preference(key: OffKey.self,
                                                       value: -g.frame(in: .named("chatspace")).minY)
                            })
                        if let f = thread.first {
                            Text(dayText(f.ts))
                                .font(.system(size: 15))
                                .foregroundColor(T.ter2)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 2)
                        }
                        ForEach(thread) { m in
                            Bubble(m: m, mine: m.from == store.meUserId, peer: peer,
                                   peerAv: peerAv, isGroup: isGroup,
                                   onPic: { mm in viewer = mm },
                                   onMenu: { mm in menuFor = mm })
                                .id(m.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 14 * T.k).padding(.top, 6).padding(.bottom, 10)
                    .frame(minHeight: geo.size.height, alignment: .bottom)
                    .animation(.spring(response: 0.35, dampingFraction: 0.86), value: thread.count)
                }
                .coordinateSpace(name: "chatspace")
                .onPreferenceChange(OffKey.self) { v in off = v }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                        sp.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: thread.count) { _ in
                    sp.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    /* ---------- 输入条（.cbar/.fld ×k：框高 34→46 / 圆角 13→19 / 字 12.5→17） ---------- */
    private var inputBar: some View {
        VStack(spacing: 0) {
            if let q = quoting {
                HStack(spacing: 10) {
                    Rectangle().fill(T.blue).frame(width: 3)
                        .clipShape(Capsule())
                    Text("引用 " + (q.name.isEmpty ? "对方" : q.name) + "：" + q.text)
                        .font(.system(size: 15)).foregroundColor(T.sec2).lineLimit(1)
                    Spacer(minLength: 0)
                    Button { H.tap(); quoting = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18)).foregroundColor(T.ter2)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 40)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.5))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(spacing: 13) {
                Button { tip("语音消息下一轮做") } label: {
                    Image(systemName: "mic")
                        .font(.system(size: 27, weight: .light))
                        .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.69))
                }
                .buttonStyle(PressStyle(scale: 0.88))

                ZStack(alignment: .leading) {
                    if draft.isEmpty {
                        Text("输入消息")
                            .font(.system(size: 17))
                            .foregroundColor(Color(red: 0.62, green: 0.65, blue: 0.70))
                    }
                    TextField("", text: $draft, axis: .vertical)
                        .font(.system(size: 17))
                        .lineLimit(1...4)
                        .foregroundColor(T.ink)
                        .tint(T.blue)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 16).frame(minHeight: 46)
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Rectangle().fill(Color.white.opacity(0.78))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(Color.white.opacity(0.70), lineWidth: 0.5))

                PhotosPicker(selection: $pick, matching: .images) {
                    Image(systemName: sending ? "hourglass" : "photo.on.rectangle")
                        .font(.system(size: 27, weight: .light))
                        .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.69))
                }

                if trimmed.isEmpty {
                    Button { tip("表情/更多面板下一轮做") } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 27, weight: .light))
                            .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.69))
                    }
                    .buttonStyle(PressStyle(scale: 0.88))
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button { sendNow() } label: {
                        Text("发送")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18).frame(height: 40)
                            .background(T.gradBlue)
                            .clipShape(Capsule())
                            .shadow(color: T.blue.opacity(0.30), radius: 6, y: 3)
                    }
                    .buttonStyle(PressStyle(scale: 0.92))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14 * T.k).padding(.top, 12).padding(.bottom, 12)
        }
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color.white.opacity(0.62))
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) { Rectangle().fill(T.sep).frame(height: 0.5) }
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: trimmed.isEmpty)
    }

    private func sendNow() {
        let t = trimmed
        guard !t.isEmpty else { return }
        H.tap(.medium)
        store.send(to: cid, text: t, quote: quoting)
        draft = ""
        quoting = nil
    }

    private func tip(_ s: String) {
        H.tap()
        withAnimation(.easeOut(duration: 0.18)) { tipText = s }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.25)) { tipText = "" }
        }
    }

    /* ---------- 长按消息：照效果图 14，白卡片 + 压暗背景（不用系统那个"把气泡顶出来"的） ---------- */
    @ViewBuilder private func menuLayer(_ m: Msg) -> some View {
        let mine = m.from == store.meUserId
        let canRecall = mine && !m.recalled
            && Date().timeIntervalSince1970 * 1000 - m.ts < 10 * 60 * 1000
        ZStack {
            Color.black.opacity(0.26).ignoresSafeArea()
                .onTapGesture { withAnimation(.easeOut(duration: 0.16)) { menuFor = nil } }
            VStack(spacing: 0) {
                menuBtn("引用", "quote.bubble") {
                    quoting = Quote(id: m.id, from: m.from,
                                    name: mine ? "我" : (m.from.isEmpty ? peer : peer),
                                    text: String(m.text.prefix(200)))
                    menuFor = nil
                }
                menuBtn("复制", "doc.on.doc") {
                    UIPasteboard.general.string = m.text
                    H.ok(); menuFor = nil
                }
                menuBtn("转发", "arrowshape.turn.up.right") {
                    forwardMsg = m; menuFor = nil
                }
                if canRecall {
                    menuBtn("撤回", "arrow.uturn.backward", danger: true) {
                        store.recall(m.id); H.warn(); menuFor = nil
                    }
                }
            }
            .frame(width: 232)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.22), radius: 26, y: 12)
        }
        .transition(.opacity)
    }

    private func menuBtn(_ title: String, _ icon: String, danger: Bool = false, _ run: @escaping () -> Void) -> some View {
        Button {
            H.tap()
            run()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 18))
                    .foregroundColor(danger ? T.red : T.sec2).frame(width: 24)
                Text(title).font(.system(size: 18)).foregroundColor(danger ? T.red : T.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20).frame(height: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle(scale: 0.97))
    }

    /* ---------- 转发选人（照效果图 18 的意思，先做成一个列表） ---------- */
    private var forwardLayer: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.28).ignoresSafeArea()
                .onTapGesture { withAnimation(.easeOut(duration: 0.18)) { forwardMsg = nil } }
            VStack(spacing: 0) {
                Text("转发到…").font(.system(size: 20, weight: .semibold)).foregroundColor(T.ink)
                    .padding(.top, 22).padding(.bottom, 12)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.convs) { c in
                            Button {
                                if let m = forwardMsg {
                                    store.send(to: c.id, text: m.text)
                                    H.ok()
                                }
                                withAnimation(.easeOut(duration: 0.18)) { forwardMsg = nil }
                                tip("已转发给 " + c.name)
                            } label: {
                                HStack(spacing: 14) {
                                    Ava(name: c.name, size: 48, online: nil,
                                        img: store.avatarId(c.id, isGroup: c.isGroup))
                                    Text(c.name).font(.system(size: 18)).foregroundColor(T.ink)
                                    Spacer()
                                    Chev()
                                }
                                .padding(.horizontal, 20).frame(height: 66)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PressStyle(scale: 0.98))
                        }
                        if store.convs.isEmpty {
                            Text("还没有可以转发的会话").font(.system(size: 17)).foregroundColor(T.sec2)
                                .padding(.vertical, 24)
                        }
                    }
                }
                .frame(maxHeight: 420)
                Button { withAnimation(.easeOut(duration: 0.18)) { forwardMsg = nil } } label: {
                    Text("取消").font(.system(size: 18)).foregroundColor(T.sec2)
                        .frame(maxWidth: .infinity).frame(height: 60)
                }
                .buttonStyle(.plain)
            }
            .background(Color(red: 0.98, green: 0.99, blue: 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 12).padding(.bottom, 12)
        }
        .transition(.opacity)
    }

    /* ---------- 看图 ---------- */
    @ViewBuilder private func viewerLayer(_ v: Msg) -> some View {
        if let fid = v.fileId, let u = store.fileURL(fid) {
            ZStack {
                Color.black
                    .opacity(max(0.16, 0.97 - Double(abs(vDrag)) / 700))
                    .ignoresSafeArea()
                NetImg(url: u, fill: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: vDrag)
                    .scaleEffect(max(0.72, 1 - abs(vDrag) / 1000))
                    .gesture(
                        DragGesture()
                            .onChanged { g in vDrag = g.translation.height }
                            .onEnded { g in
                                let far = abs(g.translation.height) > 90
                                    || abs(g.predictedEndTranslation.height) > 220
                                if far { withAnimation(.easeOut(duration: 0.20)) { viewer = nil } }
                                withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) { vDrag = 0 }
                                H.tap()
                            }
                    )
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            H.tap()
                            withAnimation(.easeOut(duration: 0.18)) { viewer = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PressStyle(scale: 0.9))
                    }
                    .padding(.horizontal, 18).padding(.top, 8)
                    Spacer()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.94)))
        }
    }

    private var toastLayer: some View {
        Text(tipText)
            .font(.system(size: 17))
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Color.black.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .transition(.opacity.combined(with: .scale(scale: 0.94)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                guard v.startLocation.x < 34 else { return }
                let w = v.translation.width, h = v.translation.height
                guard w > 0, abs(w) > abs(h) else { return }
                edgeX = min(w, 260)
            }
            .onEnded { v in
                guard v.startLocation.x < 34 else { return }
                let go = v.translation.width > 90 || v.predictedEndTranslation.width > 160
                withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) { edgeX = 0 }
                if go {
                    H.tap()
                    pm.wrappedValue.dismiss()
                }
            }
    }
}

/// 气泡（.b ×k：max-width 186→265 / padding 9-12→13-17 / 圆角 18→24 / 12.5→18）
private struct Bubble: View {
    let m: Msg
    let mine: Bool
    let peer: String
    let peerAv: String
    let isGroup: Bool
    var onPic: (Msg) -> Void
    var onMenu: (Msg) -> Void
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(alignment: mine ? .trailing : .leading, spacing: 0) {
            if !mine && isGroup {
                Text(peer)
                    .font(.system(size: 15)).foregroundColor(T.sec2)
                    .padding(.leading, 46).padding(.bottom, 6)
            }
            HStack(alignment: .top, spacing: 12) {
                if mine { Spacer(minLength: 60) }
                if !mine { Ava(name: peer, size: 34, img: peerAv) }
                bubble
                if !mine { Spacer(minLength: 60) }
            }
            if mine && !m.recalled {
                Text(m.read > 0 ? "已读" : "已送达")
                    .font(.system(size: 13))
                    .foregroundColor(m.read > 0 ? T.blue.opacity(0.75) : T.ter2)
                    .padding(.top, 6).padding(.trailing, 3)
            }
        }
    }

    @ViewBuilder private var bubble: some View {
        if m.kind == "image", let fid = m.fileId, let u = store.fileURL(fid) {
            NetImg(url: u)
                .frame(width: 192, height: 192)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.10), radius: 6, y: 3)
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .onTapGesture { H.tap(); onPic(m) }
                .onLongPressGesture(minimumDuration: 0.32) { H.tap(.medium); onMenu(m) }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if let q = m.quote, !q.text.isEmpty {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(mine ? Color.white.opacity(0.5) : T.blue.opacity(0.35))
                            .frame(width: 2.5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(q.name.isEmpty ? "对方" : q.name)
                                .font(.system(size: 14, weight: .semibold))
                            Text(q.text).font(.system(size: 15)).lineLimit(2)
                        }
                        .foregroundColor(mine ? Color.white.opacity(0.85) : T.sec2)
                    }
                    .padding(.bottom, 2)
                }
                Text(m.recalled ? "撤回了一条消息" : (m.text.isEmpty ? "[\(m.kind)]" : m.text))
                    .font(.system(size: 18))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(m.recalled ? T.sec2 : (mine ? Color.white : T.ink))
            }
            .frame(maxWidth: 265, alignment: .leading)
            .padding(.horizontal, 17).padding(.vertical, 13)
            .background(bubbleBg)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: mine ? T.blue.opacity(0.30) : Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.06),
                    radius: mine ? 9 : 6, y: mine ? 5 : 3)
            .opacity(m.recalled ? 0.75 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onLongPressGesture(minimumDuration: 0.32) { H.tap(.medium); onMenu(m) }
        }
    }

    private var bubbleBg: AnyView {
        if m.recalled { return AnyView(Color.white.opacity(0.60)) }
        if mine { return AnyView(T.gradBlue) }
        return AnyView(ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(Color.white.opacity(0.86))
        })
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
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22 * T.k)).foregroundColor(T.blue)
                }
            }
            SearchBar(placeholder: "搜索联系人")
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        NavigationLink(destination: NewFriendsView().environmentObject(store).navigationBarHidden(false)) {
                            IconRow(icon: "person.badge.plus", color: Color(red: 0.941, green: 0.569, blue: 0.247),
                                    title: "新的朋友",
                                    trailing: pendingCount > 0 ? "\(pendingCount) 条请求" : "")
                        }.buttonStyle(.plain)
                        NavigationLink(destination: GroupListView().environmentObject(store).navigationBarHidden(false)) {
                            IconRow(icon: "bubble.left.and.bubble.right.fill",
                                    color: Color(red: 0.220, green: 0.780, blue: 0.349),
                                    title: "群聊", trailing: "\(store.groups.count) 个")
                        }.buttonStyle(.plain)
                    }
                    .glassCard().padding(.horizontal, 14 * T.k).padding(.bottom, 20)

                    HStack {
                        Text("好友 · \(store.friends.count)")
                            .font(.system(size: 15)).foregroundColor(T.sec2)
                        Spacer()
                    }
                    .padding(.horizontal, 30).padding(.bottom, 10)

                    VStack(spacing: 0) {
                        ForEach(store.friends) { f in
                            NavigationLink(destination: FriendProfileView(pid: f.id)
                                .environmentObject(store).navigationBarHidden(false)) {
                                HStack(spacing: 16) {
                                    Ava(name: f.display, size: 56, online: f.online, img: f.avatar)
                                    Text(f.display).font(.system(size: 18)).foregroundColor(T.ink)
                                    Spacer()
                                }
                                .padding(.horizontal, 20).frame(height: 76)
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                        if store.friends.isEmpty {
                            Text("还没有好友").font(.system(size: 18)).foregroundColor(T.sec2)
                                .padding(.vertical, 20)
                        }
                    }
                    .glassCard().padding(.horizontal, 14 * T.k)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

/// 群聊列表（照效果图 31 的意思：全员群 + 我进的群）
struct GroupListView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) private var pm
    var body: some View {
        ZStack(alignment: .top) {
            AppBg()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button { H.tap(); pm.wrappedValue.dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold)).foregroundColor(T.blue)
                            .frame(width: 26, height: 40, alignment: .leading)
                    }
                    .buttonStyle(PressStyle(scale: 0.85))
                    Text("群聊").font(.system(size: 20, weight: .semibold)).foregroundColor(T.ink)
                    Spacer()
                }
                .padding(.horizontal, 18).frame(height: 58)

                ScrollView {
                    VStack(spacing: 0) {
                        if store.allIn {
                            NavigationLink(destination: ChatScreen(cid: "all", isGroup: true).environmentObject(store)) {
                                HStack(spacing: 16) {
                                    Ava(name: "全员群", size: 56)
                                    Text("全员群").font(.system(size: 18)).foregroundColor(T.ink)
                                    Spacer()
                                    Chev()
                                }
                                .padding(.horizontal, 20).frame(height: 76)
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                        ForEach(store.groups) { g in
                            NavigationLink(destination: ChatScreen(cid: g.id, isGroup: true).environmentObject(store)) {
                                HStack(spacing: 16) {
                                    Ava(name: g.name, size: 56)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(g.name).font(.system(size: 18)).foregroundColor(T.ink)
                                        Text("\(g.members.count) 人").font(.system(size: 15)).foregroundColor(T.sec2)
                                    }
                                    Spacer()
                                    Chev()
                                }
                                .padding(.horizontal, 20).frame(height: 76)
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                        if !store.allIn && store.groups.isEmpty {
                            Text("还没进任何群").font(.system(size: 18)).foregroundColor(T.sec2)
                                .padding(.top, 60)
                        }
                    }
                    .glassCard().padding(.horizontal, 14 * T.k).padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/// 通讯录那种「小圆角图标 + 标题 + 右边小字」的行（×k：图标 30 / 字 18 / 行高 68）
struct IconRow: View {
    let icon: String
    let color: Color
    let title: String
    var trailing: String = ""
    var sub: String = ""
    var chev = true
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.88), color], startPoint: .top, endPoint: .bottom))
                    .frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 18)).foregroundColor(T.ink)
                if !sub.isEmpty { Text(sub).font(.system(size: 14)).foregroundColor(T.sec2) }
            }
            Spacer()
            if !trailing.isEmpty {
                Text(trailing).font(.system(size: 15)).foregroundColor(T.sec2)
            }
            if chev { Chev() }
        }
        .padding(.horizontal, 20).frame(height: 68)
        .contentShape(Rectangle())
    }
}

/// 设计稿里那颗 ›（#CFD7E0）×k ≈ 17
struct Chev: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color(red: 0.812, green: 0.843, blue: 0.878))
    }
}

/* ==================== 11 我 ==================== */
struct MePage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var session: Session
    private var nick: String { store.meName.isEmpty ? session.myName : store.meName }
    /// BB鸡号：优先用服务器 WS 给的那份（store.meId），没有才退回登录时存的
    private var myBbji: String { store.meId.isEmpty ? session.myId : store.meId }
    var body: some View {
        VStack(spacing: 0) {
            TopTitle("我")
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Ava(name: nick.isEmpty ? "我" : nick, size: 116, img: store.myAvatar)
                        Text(nick.isEmpty ? "—" : nick)
                            .font(.system(size: 22, weight: .semibold)).foregroundColor(T.ink)
                            .padding(.top, 16)
                        Text("BB鸡号 \(myBbji.isEmpty ? "—" : myBbji)")
                            .font(.system(size: 15)).foregroundColor(T.sec2)
                            .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
                    .glassCard().padding(.horizontal, 14 * T.k).padding(.bottom, 20)

                    VStack(spacing: 0) {
                        NavigationLink(destination: MyProfileView().environmentObject(store)
                            .environmentObject(session).navigationBarHidden(false)) {
                            IconRow(icon: "person.text.rectangle", color: T.blue, title: "我的资料")
                        }.buttonStyle(.plain)
                        NavigationLink(destination: WebShell().navigationBarHidden(false).navigationBarTitle("设计稿")) {
                            IconRow(icon: "square.grid.2x2", color: Color(red: 0.98, green: 0.62, blue: 0.24),
                                    title: "设计稿（v5 · 61 屏）")
                        }.buttonStyle(.plain)
                        IconRow(icon: "wifi", color: Color(red: 0.55, green: 0.36, blue: 0.95),
                                title: "连接状态", trailing: store.connected ? "已连上服务器" : "重连中…",
                                chev: false)
                    }
                    .glassCard().padding(.horizontal, 14 * T.k).padding(.bottom, 20)

                    VStack(spacing: 0) {
                        Button {
                            store.disconnect(); session.logout()
                        } label: {
                            Text("退出登录").font(.system(size: 18)).foregroundColor(T.red)
                                .frame(maxWidth: .infinity).frame(height: 68)
                        }
                    }
                    .glassCard().padding(.horizontal, 14 * T.k)

                    Text("版本 " + appVersionText())
                        .font(.system(size: 14)).foregroundColor(T.ter2)
                        .frame(maxWidth: .infinity).padding(.top, 20)
                }
                .padding(.bottom, 24)
            }
        }
    }
}
