import SwiftUI
import PhotosUI

/* 2026-10-07 重画（用户真机截图反馈："有些地方很别扭，说不上来"）：
   这几页以前用系统的 .navigationTitle + List：
     · 左上角是**英文 Back**；· 底下是系统灰 #F2F2F7 + 系统白卡，跟自绘的玻璃/渐变两套风格。
   现在统一：DZNavBar 自绘顶栏 + AppBg 渐变 + glassCard + 真机尺寸（头像 48-72 / 正文 15-17 / 行高 52-56）。
   另外补上空状态：「新的朋友」「加好友」以前半屏空白。 */

/* ==================== 21 好友资料 ==================== */
struct FriendProfileView: View {
    @EnvironmentObject var store: Store
    let pid: String
    @State private var remark = ""
    @State private var editing = false
    @State private var tip = ""

    private var p: Person? { store.people[pid] }
    private var bbji: String { (p?.account).flatMap { $0.isEmpty ? nil : $0 } ?? "—" }

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                DZNavBar("资料")
                ScrollView {
                    VStack(spacing: 12) {
                        /* 左上横排（跟「我」页一套）：头像 + 名字/号 + 在线小字 */
                        HStack(spacing: 14) {
                            Ava(name: p?.display ?? "?", size: 64, online: p?.online, img: p?.avatar ?? "")
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p?.display ?? "—")
                                    .font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
                                Text("BB鸡号 \(bbji)")
                                    .font(.system(size: 13)).foregroundColor(T.sec2)
                                Text(p?.online == true ? "在线" : "不在线")
                                    .font(.system(size: 12))
                                    .foregroundColor(p?.online == true ? T.green : T.sec2)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .glassCard(16).padding(.horizontal, 14)

                        VStack(spacing: 0) {
                            NavigationLink(destination: ChatScreen(cid: pid, isGroup: false).environmentObject(store)) {
                                MenuRow(icon: "bubble.left.fill", color: T.blue, title: "发消息")
                            }.buttonStyle(.plain)
                            RowDivider()
                            Button { remark = p?.remark ?? ""; editing = true } label: {
                                MenuRow(icon: "pencil", color: Color(red: 0.98, green: 0.62, blue: 0.24),
                                        title: "设置备注",
                                        trailing: (p?.remark).flatMap { $0.isEmpty ? nil : $0 } ?? "没设")
                            }.buttonStyle(.plain)
                        }
                        .glassCard(16).padding(.horizontal, 14)

                        VStack(spacing: 0) {
                            Button {
                                store.friendReq(to: pid, msg: "")
                                tip = "好友申请发出了"
                            } label: {
                                Text("加好友（还不是好友时才用得上）")
                                    .font(.system(size: 15)).foregroundColor(T.blue)
                                    .frame(maxWidth: .infinity).frame(height: 52)
                            }.buttonStyle(PressStyle(scale: 0.98))
                            RowDivider()
                            Button {
                                store.delFriend(id: pid)
                                tip = "删掉了"
                            } label: {
                                Text("删除好友")
                                    .font(.system(size: 15)).foregroundColor(T.red)
                                    .frame(maxWidth: .infinity).frame(height: 52)
                            }.buttonStyle(PressStyle(scale: 0.98))
                        }
                        .glassCard(16).padding(.horizontal, 14)

                        if !tip.isEmpty {
                            Text(tip).font(.system(size: 12.5)).foregroundColor(T.sec2)
                        }
                    }
                    .padding(.top, 6).padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("设置备注", isPresented: $editing) {
            TextField("备注（最多 24 字）", text: $remark)
            Button("取消", role: .cancel) {}
            Button("保存") { store.setRemark(id: pid, remark: remark) }
        }
    }
}

/* ==================== 23 我的资料 ==================== */
struct MyProfileView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var session: Session
    @State private var pick: PhotosPickerItem? = nil
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var tip = ""
    @State private var showDraft = false

    private var nick: String { session.myName.isEmpty ? "我" : session.myName }

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                DZNavBar("我的资料")
                ScrollView {
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $pick, matching: .images) {
                            HStack(spacing: 14) {
                                ZStack(alignment: .bottomTrailing) {
                                    Ava(name: nick, size: 64, img: store.myAvatar)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Circle().fill(T.gradBlue))
                                        .overlay(Circle().stroke(.white, lineWidth: 2))
                                        .offset(x: 3, y: 2)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(nick).font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
                                    Text("点这里换头像").font(.system(size: 13)).foregroundColor(T.sec2)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressStyle(scale: 0.98))
                        .glassCard(16).padding(.horizontal, 14)

                        VStack(spacing: 0) {
                            Button { nameDraft = session.myName; editingName = true } label: {
                                SettingRow(title: "昵称", value: session.myName)
                            }.buttonStyle(.plain)
                            RowDivider()
                            SettingRow(title: "BB鸡号", value: session.myId)
                            RowDivider()
                            SettingRow(title: "绑定邮箱", value: store.myEmail.isEmpty ? "—" : store.myEmail)
                        }
                        .glassCard(16).padding(.horizontal, 14)

                        if !tip.isEmpty { Text(tip).font(.system(size: 12.5)).foregroundColor(T.sec2) }

                        VStack(spacing: 0) {
                            Button { showDraft = true } label: {
                                MenuRow(icon: "square.grid.2x2", color: Color(red: 0.98, green: 0.62, blue: 0.24),
                                        title: "设计稿（v5 · 61 屏）")
                            }.buttonStyle(.plain)
                            RowDivider()
                            SettingRow(title: "版本", value: appVersionText())
                        }
                        .glassCard(16).padding(.horizontal, 14)

                        Text("改密码 / 退出登录在「我」那一页")
                            .font(.system(size: 12)).foregroundColor(T.ter2)
                            .padding(.top, 4)
                    }
                    .padding(.top, 6).padding(.bottom, 26)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showDraft) {
            WebShell().navigationBarHidden(false).navigationBarTitle("设计稿")
        }
        .alert("改昵称", isPresented: $editingName) {
            TextField("最多 24 字", text: $nameDraft)
            Button("取消", role: .cancel) {}
            Button("保存") {
                Task {
                    let e = await store.setName(nameDraft)
                    tip = e.isEmpty ? "名字改好了" : e
                }
            }
        }
        .onChange(of: pick) { item in
            guard let item else { return }
            Task {
                tip = "正在传头像…"
                if let d = try? await item.loadTransferable(type: Data.self) {
                    let e = await store.uploadAvatar(data: d, name: "av_\(Int(Date().timeIntervalSince1970)).jpg")
                    tip = e.isEmpty ? "头像换好了" : e
                }
                pick = nil
            }
        }
    }
}

/* ==================== 10 新的朋友 ==================== */
struct NewFriendsView: View {
    @EnvironmentObject var store: Store
    private var incoming: [FriendReq] { store.reqs.filter { !$0.outgoing && $0.state == "pending" } }
    private var outgoing: [FriendReq] { store.reqs.filter { $0.outgoing } }

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                DZNavBar("新的朋友")
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(spacing: 0) {
                            SecLabel(text: "等我同意")
                            VStack(spacing: 0) {
                                if incoming.isEmpty {
                                    EmptyHint(icon: "person.crop.circle.badge.questionmark", text: "还没有人申请加你\n对方搜到你的 BB鸡号就能加")
                                } else {
                                    ForEach(incoming) { r in
                                        HStack(spacing: 12) {
                                            Ava(name: store.people[r.userId]?.display ?? "?",
                                                size: 48, online: store.people[r.userId]?.online,
                                                img: store.people[r.userId]?.avatar ?? "")
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(store.people[r.userId]?.display ?? r.userId)
                                                    .font(.system(size: 16)).foregroundColor(T.ink)
                                                if !r.msg.isEmpty {
                                                    Text(r.msg).font(.system(size: 13)).foregroundColor(T.sec2)
                                                }
                                            }
                                            Spacer(minLength: 0)
                                            PillBtn(title: "同意") { store.friendAck(from: r.userId, accept: true) }
                                            PillBtn(title: "拒绝", kind: .gray) { store.friendAck(from: r.userId, accept: false) }
                                        }
                                        .padding(.horizontal, 14).frame(height: 68)
                                    }
                                }
                            }
                            .glassCard(16).padding(.horizontal, 14)
                        }

                        VStack(spacing: 0) {
                            SecLabel(text: "我发出去的")
                            VStack(spacing: 0) {
                                if outgoing.isEmpty {
                                    EmptyHint(icon: "paperplane", text: "还没发过申请\n在通讯录右上角「＋」里搜 BB鸡号")
                                } else {
                                    ForEach(outgoing) { r in
                                        HStack(spacing: 12) {
                                            Ava(name: store.people[r.userId]?.display ?? "?", size: 48,
                                                img: store.people[r.userId]?.avatar ?? "")
                                            Text(store.people[r.userId]?.display ?? r.userId)
                                                .font(.system(size: 16)).foregroundColor(T.ink)
                                            Spacer(minLength: 0)
                                            Text(r.state == "accepted" ? "已同意" : (r.state == "rejected" ? "被拒绝" : "等对方同意"))
                                                .font(.system(size: 13))
                                                .foregroundColor(r.state == "accepted" ? T.green : T.sec2)
                                        }
                                        .padding(.horizontal, 14).frame(height: 60)
                                    }
                                }
                            }
                            .glassCard(16).padding(.horizontal, 14)
                        }
                    }
                    .padding(.top, 6).padding(.bottom, 26)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/* ==================== 加好友（搜 BB鸡号） ==================== */
struct AddFriendView: View {
    @EnvironmentObject var store: Store
    @State private var q = ""
    @State private var tip = ""

    private var hit: Person? { store.findUser(q) }
    private var typed: Bool { !q.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                DZNavBar("加好友")
                ScrollView {
                    VStack(spacing: 14) {
                        HStack(spacing: 9) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium)).foregroundColor(T.sec2)
                            TextField("输 BB鸡号 / 账号", text: $q)
                                .font(.system(size: 15)).foregroundColor(T.ink)
                                .textInputAutocapitalization(.never).disableAutocorrection(true)
                            if typed {
                                Button { q = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16)).foregroundColor(T.ter2)
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12).frame(height: 40)
                        .glassCard(12).padding(.horizontal, 14)

                        if let p = hit {
                            HStack(spacing: 14) {
                                Ava(name: p.display, size: 64, online: p.online, img: p.avatar)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(p.display).font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
                                    Text("BB鸡号 \(p.account)").font(.system(size: 13)).foregroundColor(T.sec2)
                                }
                                Spacer(minLength: 0)
                                if p.id == store.meUserId {
                                    Text("这是你自己").font(.system(size: 13)).foregroundColor(T.sec2)
                                } else if store.friends.contains(where: { $0.id == p.id }) {
                                    Text("已经是好友").font(.system(size: 13)).foregroundColor(T.green)
                                } else {
                                    PillBtn(title: "加好友") {
                                        store.friendReq(to: p.id, msg: "")
                                        tip = "申请发出了，等对方同意"
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .glassCard(16).padding(.horizontal, 14)
                        } else if typed {
                            VStack(spacing: 0) {
                                EmptyHint(icon: "magnifyingglass", text: "没找到「\(q)」\n检查一下有没有输错；对方也可能还没注册")
                            }
                            .glassCard(16).padding(.horizontal, 14)
                        } else {
                            VStack(spacing: 0) {
                                EmptyHint(icon: "person.badge.plus", text: "输完整的 BB鸡号，比如 xiangxiang\n搜到之后点「加好友」等对方同意")
                            }
                            .glassCard(16).padding(.horizontal, 14)
                        }

                        if !tip.isEmpty {
                            Text(tip).font(.system(size: 13)).foregroundColor(T.blue)
                        }
                    }
                    .padding(.top, 6).padding(.bottom, 26)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

/* ==================== 这一套页面里共用的小件 ==================== */
/// 卡里的分隔线（比系统 Divider 细、颜色跟 T.sep 一致）
struct RowDivider: View {
    var body: some View {
        Rectangle().fill(T.sep).frame(height: 0.5).padding(.leading, 56)
    }
}

/// 「小圆角图标 + 标题 + 右边小字 + ›」的行（真机：图标 26 / 标题 16 / 行高 54）
struct MenuRow: View {
    let icon: String
    let color: Color
    let title: String
    var trailing: String = ""
    var chev = true
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.88), color], startPoint: .top, endPoint: .bottom))
                    .frame(width: 26, height: 26)
                Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
            }
            Text(title).font(.system(size: 16)).foregroundColor(T.ink)
            Spacer(minLength: 0)
            if !trailing.isEmpty {
                Text(trailing).font(.system(size: 13.5)).foregroundColor(T.sec2)
            }
            if chev { Chev() }
        }
        .padding(.horizontal, 16).frame(height: 54)
        .contentShape(Rectangle())
    }
}

/// 「标题 + 右边灰字」的值行（昵称 / BB鸡号 / 邮箱 这种）
struct SettingRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(.system(size: 16)).foregroundColor(T.ink)
            Spacer(minLength: 0)
            Text(value).font(.system(size: 14)).foregroundColor(T.sec2)
                .lineLimit(1).truncationMode(.middle)
        }
        .padding(.horizontal, 16).frame(height: 54)
        .contentShape(Rectangle())
    }
}
