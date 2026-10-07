import SwiftUI
import UIKit
import PhotosUI

/* ==================================================================
   主界面（回 A：原生精修 / 重塑）
   —— 完全自绘：不用系统 List、导航栏、TabView；材质用 .ultraThinMaterial，
      动效全走 spring，交互补触感，字号字距照效果图一项一项写死。
   本轮做的两页：06 消息列表、12 单聊（其余页面下一轮照同一套改）。
   效果图对应：mobile-ui.html（v5 + v3 质感层）
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
    @State private var off: CGFloat = 0        // 列表滚了多少（贴边毛玻璃用）
    @State private var openRow: String? = nil  // 当前左滑打开的那一行
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

    /* 大标题 + 搜索：照 .ltitle / .srch；
       滚起来之后整条变成毛玻璃 + 一条 .5 的分线（iOS 的 scrollEdge 效果） */
    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                Text("消息")
                    .font(.system(size: 25, weight: .bold))
                    .kerning(-0.9)
                    .foregroundColor(T.ink)
                Spacer(minLength: 0)
                NavigationLink(destination: AddFriendView().environmentObject(store).navigationBarHidden(false)) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(T.blue)
                }
                .buttonStyle(PressStyle(scale: 0.88))
            }
            .padding(.horizontal, 18).padding(.top, 2).padding(.bottom, 12)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.68))
                ZStack(alignment: .leading) {
                    if q.isEmpty {
                        Text("搜索聊天、联系人、消息")
                            .font(.system(size: 12)).foregroundColor(T.hint)
                    }
                    TextField("", text: $q)
                        .font(.system(size: 12))
                        .foregroundColor(T.ink)
                        .tint(T.blue)
                        .submitLabel(.search)
                        .disableAutocorrection(true)
                }
                if !q.isEmpty {
                    Button { q = ""; H.tap() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.72, green: 0.76, blue: 0.81))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10).frame(height: 34)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.60), lineWidth: 0.5))
            .shadow(color: Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.04), radius: 4, y: 2)
            .padding(.horizontal, 14).padding(.bottom, 10)
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
            .padding(.bottom, 14)
        }
        .coordinateSpace(name: "chatlist")
        .onPreferenceChange(OffKey.self) { v in off = v }
        .scrollDismissesKeyboard(.interactively)
    }

    private func row(_ c: Conv) -> some View {
        SwipeRow(id: c.id, openID: $openRow, height: 54,
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
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(q.isEmpty ? (store.connected ? "还没有聊天" : "连接中…") : "没找到")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(T.ink)
                Text(q.isEmpty ? "在电脑端先跟人聊两句，这边就会出现" : "换个词试试")
                    .font(.system(size: 12)).foregroundColor(T.sec2)
            }
            .frame(maxWidth: .infinity).padding(.top, 90)
            Spacer(minLength: 0)
        }
    }
}

/// 一行会话（v3 的 .li：padding 4/16、头像 46、名字 14/600/字距 -.25、预览 12.5、时间 11、红点 18）
private struct ConvRow: View {
    let c: Conv
    var avatar: String = ""
    var body: some View {
        HStack(spacing: 11) {
            Ava(name: c.name, size: 46, online: c.isGroup ? nil : c.online, img: avatar)
            VStack(alignment: .leading, spacing: 3) {
                Text(c.name)
                    .font(.system(size: 14, weight: .semibold))
                    .kerning(-0.25)
                    .foregroundColor(T.ink)
                    .lineLimit(1)
                Text(c.text)
                    .font(.system(size: 12.5))
                    .foregroundColor(T.sec2)
                    .lineLimit(1)
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
        .frame(height: 54)
        .contentShape(Rectangle())
    }
}

/* ==================== 左滑（自绘，照 07 会话左滑） ==================== */
struct SwipeAct: Identifiable {
    let id = UUID()
    let title: String
    let bg: AnyView
    let action: () -> Void
}

struct SwipeRow<Content: View>: View {
    let id: String
    @Binding var openID: String?
    var height: CGFloat = 54
    var tint: Color = .clear
    let actions: [SwipeAct]
    @ViewBuilder var content: () -> Content

    @State private var dx: CGFloat = 0
    @State private var dragging = false
    @State private var crossed = false

    private var width: CGFloat { CGFloat(actions.count) * 56 }
    private var reveal: CGFloat { max(0, -dx) }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 后面：露出多少就摆多少（从右边往外推）
            HStack(spacing: 0) {
                ForEach(actions) { a in
                    Button {
                        H.tap(.medium)
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) { dx = 0 }
                        openID = nil
                        a.action()
                    } label: {
                        a.bg
                            .frame(width: 56, height: height)
                            .overlay(Text(a.title)
                                .font(.system(size: 11, weight: .medium))
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
                    // 先判断是横着划还是上下滚：竖着的一律不算（不然列表没法滚）
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
    @State private var off: CGFloat = 0            // 消息滚了多少
    @State private var edgeX: CGFloat = 0          // 左边缘返回的手势位移
    @State private var viewer: Msg? = nil          // 看图
    @State private var vDrag: CGFloat = 0
    @State private var tipText = ""

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
            // 左边缘返回（自绘导航栏没有系统手势，这里自己补一个：
            // 只认从最左边 34pt 起手、且是横着划的，不会挡住顶栏那颗返回键）
            .simultaneousGesture(backDrag)

            if let v = viewer { viewerLayer(v) }
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

    /* ---------- 顶栏（.navbar：高 42 / 头像 30 / 名字 14.5/600/字距 -.2） ---------- */
    private var navbar: some View {
        HStack(spacing: 8) {
            Button {
                H.tap()
                pm.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(T.blue)
                    .frame(width: 16, height: 30, alignment: .leading)
            }
            .buttonStyle(PressStyle(scale: 0.85))

            Ava(name: peer, size: 30,
                online: isGroup ? nil : (store.people[cid]?.online ?? false),
                img: peerAv)

            Text(peer)
                .font(.system(size: 14.5, weight: .semibold))
                .kerning(-0.2)
                .foregroundColor(T.ink)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 13) {
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
        .padding(.horizontal, 14).frame(height: 42)
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
        Image(systemName: name).font(.system(size: 17, weight: .regular)).foregroundColor(T.blue)
    }

    /* ---------- 消息区（.chat：padding 4/14/8 + 行距 8） ---------- */
    private var msgs: some View {
        ScrollViewReader { sp in
            ScrollView {
                LazyVStack(spacing: 8) {
                    Color.clear.frame(height: 0)
                        .background(GeometryReader { g in
                            Color.clear.preference(key: OffKey.self,
                                                   value: -g.frame(in: .named("chatspace")).minY)
                        })
                    if let f = thread.first {
                        Text(dayText(f.ts))
                            .font(.system(size: 10.5))
                            .foregroundColor(T.ter2)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 2)
                    }
                    ForEach(thread) { m in
                        Bubble(m: m, mine: m.from == store.meUserId, peer: peer,
                               peerAv: peerAv, isGroup: isGroup,
                               onPic: { mm in viewer = mm })
                            .id(m.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 10)
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

    /* ---------- 输入条（.cbar + .fld：高 34 / 圆角 13 / 玻璃） ---------- */
    private var inputBar: some View {
        HStack(spacing: 9) {
            Button { tip("语音消息下一轮做") } label: {
                Image(systemName: "mic")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.69))
            }
            .buttonStyle(PressStyle(scale: 0.88))

            ZStack(alignment: .leading) {
                if draft.isEmpty {
                    Text("输入消息")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.62, green: 0.65, blue: 0.70))
                }
                TextField("", text: $draft, axis: .vertical)
                    .font(.system(size: 12.5))
                    .lineLimit(1...4)
                    .foregroundColor(T.ink)
                    .tint(T.blue)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 12).frame(minHeight: 34)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(Color.white.opacity(0.78))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.70), lineWidth: 0.5))

            PhotosPicker(selection: $pick, matching: .images) {
                Image(systemName: sending ? "hourglass" : "photo.on.rectangle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.69))
            }

            if trimmed.isEmpty {
                Button { tip("表情/更多面板下一轮做") } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color(red: 0.60, green: 0.64, blue: 0.69))
                }
                .buttonStyle(PressStyle(scale: 0.88))
                .transition(.scale.combined(with: .opacity))
            } else {
                Button { sendNow() } label: {
                    Text("发送")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14).frame(height: 30)
                        .background(T.gradBlue)
                        .clipShape(Capsule())
                        .shadow(color: T.blue.opacity(0.30), radius: 6, y: 3)
                }
                .buttonStyle(PressStyle(scale: 0.92))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14).padding(.top, 9).padding(.bottom, 10)
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
        store.send(to: cid, text: t)
        draft = ""
    }

    private func tip(_ s: String) {
        H.tap()
        withAnimation(.easeOut(duration: 0.18)) { tipText = s }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.25)) { tipText = "" }
        }
    }

    /* ---------- 看图（点开大图；往下拖关掉） ---------- */
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
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PressStyle(scale: 0.9))
                    }
                    .padding(.horizontal, 16).padding(.top, 6)
                    Spacer()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.94)))
        }
    }

    private var toastLayer: some View {
        Text(tipText)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Color.black.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

/// 气泡（v3 的 .b：max-width 186 / padding 9-12 / 圆角 18 / 12.5px / 行高 1.45）
private struct Bubble: View {
    let m: Msg
    let mine: Bool
    let peer: String
    let peerAv: String
    let isGroup: Bool
    var onPic: (Msg) -> Void
    @EnvironmentObject var store: Store

    private var canRecall: Bool {
        mine && !m.recalled
            && Date().timeIntervalSince1970 * 1000 - m.ts < 10 * 60 * 1000
    }

    var body: some View {
        VStack(alignment: mine ? .trailing : .leading, spacing: 0) {
            if !mine && isGroup {
                Text(peer)
                    .font(.system(size: 10.5)).foregroundColor(T.sec2)
                    .padding(.leading, 32).padding(.bottom, 4)
            }
            HStack(alignment: .top, spacing: 8) {
                if mine { Spacer(minLength: 44) }
                if !mine { Ava(name: peer, size: 24, img: peerAv) }
                bubble
                if !mine { Spacer(minLength: 44) }
            }
            if mine && !m.recalled {
                Text(m.read > 0 ? "已读" : "已送达")
                    .font(.system(size: 9.5))
                    .foregroundColor(m.read > 0 ? T.blue.opacity(0.75) : T.ter2)
                    .padding(.top, 4).padding(.trailing, 2)
            }
        }
    }

    @ViewBuilder private var bubble: some View {
        if m.kind == "image", let fid = m.fileId, let u = store.fileURL(fid) {
            NetImg(url: u)
                .frame(width: 132, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.10), radius: 5, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onTapGesture { H.tap(); onPic(m) }
                .contextMenu { menu }
        } else {
            Text(m.recalled ? "撤回了一条消息" : (m.text.isEmpty ? "[\(m.kind)]" : m.text))
                .font(.system(size: 12.5))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(m.recalled ? T.sec2 : (mine ? Color.white : T.ink))
                .frame(maxWidth: 186, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(bubbleBg)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: mine ? T.blue.opacity(0.30) : Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.06),
                        radius: mine ? 8 : 5, y: mine ? 4 : 2)
                .opacity(m.recalled ? 0.75 : 1)
                .contextMenu { menu }
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

    @ViewBuilder private var menu: some View {
        Button { UIPasteboard.general.string = m.text; H.ok() } label: {
            Label("复制", systemImage: "doc.on.doc")
        }
        if canRecall {
            Button(role: .destructive) { store.recall(m.id); H.warn() } label: {
                Label("撤回", systemImage: "arrow.uturn.backward")
            }
        }
    }
}

/* ==================== 09 通讯录（下一轮按同一套改） ==================== */
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
                    VStack(spacing: 0) {
                        NavigationLink(destination: NewFriendsView().environmentObject(store).navigationBarHidden(false)) {
                            IconRow(icon: "person.badge.plus", color: Color(red: 0.941, green: 0.569, blue: 0.247),
                                    title: "新的朋友",
                                    trailing: pendingCount > 0 ? "\(pendingCount) 条请求" : "")
                        }.buttonStyle(.plain)
                        ForEach(store.groups) { g in
                            NavigationLink(destination: ChatScreen(cid: g.id, isGroup: true)
                                .environmentObject(store)) {
                                IconRow(icon: "bubble.left.and.bubble.right.fill",
                                        color: Color(red: 0.220, green: 0.780, blue: 0.349),
                                        title: g.name, trailing: "\(g.members.count) 个")
                            }.buttonStyle(.plain)
                        }
                    }
                    .glassCard().padding(.horizontal, 14).padding(.bottom, 14)

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
                    .glassCard().padding(.horizontal, 14)
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
    var sub: String = ""
    var chev = true                       // 设计稿里这类行右边都有一颗 ›
    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.88), color], startPoint: .top, endPoint: .bottom))
                    .frame(width: 22, height: 22)
                Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13.5)).foregroundColor(T.ink)
                if !sub.isEmpty { Text(sub).font(.system(size: 10.5)).foregroundColor(T.sec2) }
            }
            Spacer()
            if !trailing.isEmpty {
                Text(trailing).font(.system(size: 11.5)).foregroundColor(T.sec2)
            }
            if chev { Chev() }
        }
        .padding(.horizontal, 16).frame(height: 50)
        .contentShape(Rectangle())
    }
}

/// 设计稿里那颗 ›（#CFD7E0，12/600）
struct Chev: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(red: 0.812, green: 0.843, blue: 0.878))
    }
}

/* ==================== 11 我（下一轮按同一套改） ==================== */
struct MePage: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var session: Session
    private var nick: String { store.meName.isEmpty ? session.myName : store.meName }
    var body: some View {
        VStack(spacing: 0) {
            TopTitle("我")
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Ava(name: nick.isEmpty ? "我" : nick, size: 84, img: store.myAvatar)
                        Text(nick.isEmpty ? "—" : nick)
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(T.ink)
                            .padding(.top, 11)
                        Text("BB鸡号 \(session.myId)").font(.system(size: 11)).foregroundColor(T.sec2)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
                    .glassCard().padding(.horizontal, 14).padding(.bottom, 14)

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
                    .glassCard().padding(.horizontal, 14).padding(.bottom, 14)

                    VStack(spacing: 0) {
                        Button {
                            store.disconnect(); session.logout()
                        } label: {
                            Text("退出登录").font(.system(size: 13.5)).foregroundColor(T.red)
                                .frame(maxWidth: .infinity).frame(height: 50)
                        }
                    }
                    .glassCard().padding(.horizontal, 14)

                    Text("版本 " + appVersionText())
                        .font(.system(size: 10.5)).foregroundColor(T.ter2)
                        .frame(maxWidth: .infinity).padding(.top, 14)
                }
                .padding(.bottom, 16)
            }
        }
    }
}
