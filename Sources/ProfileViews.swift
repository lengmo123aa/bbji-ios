import SwiftUI
import PhotosUI

/* ==================== 21 好友资料 ==================== */
struct FriendProfileView: View {
    @EnvironmentObject var store: Store
    let pid: String
    @State private var remark = ""
    @State private var editing = false
    @State private var tip = ""

    private var p: Person? { store.people[pid] }
    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        Ava(name: p?.display ?? "?", size: 84, online: p?.online)
                        Text(p?.display ?? "—").font(.system(size: 18, weight: .semibold)).foregroundColor(T.ink)
                        Text("BB鸡号 \((p?.account).flatMap { $0.isEmpty ? nil : $0 } ?? "—")")
                            .font(.system(size: 11)).foregroundColor(T.gray)
                        Text(p?.online == true ? "在线" : "不在线")
                            .font(.system(size: 11)).foregroundColor(p?.online == true ? T.green : T.gray)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
                    .glassCard()
                    .padding(.horizontal, 18)

                    VStack(spacing: 0) {
                        NavigationLink(destination: ChatScreen(cid: pid, isGroup: false).environmentObject(store)) {
                            HStack {
                                Text("发消息").font(.system(size: 13.5))
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 0.79, green: 0.82, blue: 0.85))
                            }
                            .padding(.horizontal, 16).frame(height: 46)
                        }
                        Divider().opacity(0.5)
                        Button { remark = p?.remark ?? ""; editing = true } label: {
                            HStack {
                                Text("设置备注").font(.system(size: 13.5)).foregroundColor(T.ink)
                                Spacer()
                                Text((p?.remark).flatMap { $0.isEmpty ? nil : $0 } ?? "没设")
                                    .font(.system(size: 12)).foregroundColor(T.gray)
                            }
                            .padding(.horizontal, 16).frame(height: 46)
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, 18)

                    VStack(spacing: 0) {
                        Button {
                            store.friendReq(to: pid, msg: "")
                            tip = "好友申请发出了"
                        } label: {
                            Text("加好友（不是好友才用得上）").font(.system(size: 13))
                                .foregroundColor(T.blue).frame(maxWidth: .infinity).frame(height: 46)
                        }
                        Divider().opacity(0.5)
                        Button(role: .destructive) {
                            store.delFriend(id: pid)
                            tip = "删掉了"
                        } label: {
                            Text("删除好友").font(.system(size: 13))
                                .foregroundColor(T.red).frame(maxWidth: .infinity).frame(height: 46)
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, 18)

                    if !tip.isEmpty { Text(tip).font(.system(size: 11.5)).foregroundColor(T.gray) }
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("资料")
        .navigationBarTitleDisplayMode(.inline)
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

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        PhotosPicker(selection: $pick, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                Ava(name: session.myName.isEmpty ? "我" : session.myName, size: 84, img: store.myAvatar)
                                Image(systemName: "plus.circle.fill").font(.system(size: 24))
                                    .foregroundColor(T.blue)
                                    .background(Circle().fill(.white))
                            }
                        }
                        Text("点头像可以换一张").font(.system(size: 11)).foregroundColor(T.gray)
                        Text(session.myName.isEmpty ? "—" : session.myName)
                            .font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
                    .glassCard().padding(.horizontal, 18)

                    VStack(spacing: 0) {
                        Button {
                            nameDraft = session.myName; editingName = true
                        } label: {
                            HStack {
                                Text("昵称").font(.system(size: 13.5)).foregroundColor(T.ink)
                                Spacer()
                                Text(session.myName).font(.system(size: 12)).foregroundColor(T.gray)
                            }
                            .padding(.horizontal, 16).frame(height: 46)
                        }
                        Divider().opacity(0.5)
                        HStack {
                            Text("BB鸡号").font(.system(size: 13.5)).foregroundColor(T.ink)
                            Spacer()
                            Text(session.myId).font(.system(size: 12)).foregroundColor(T.gray)
                        }
                        .padding(.horizontal, 16).frame(height: 46)
                        Divider().opacity(0.5)
                        HStack {
                            Text("绑定邮箱").font(.system(size: 13.5)).foregroundColor(T.ink)
                            Spacer()
                            Text(store.myEmail.isEmpty ? "—" : store.myEmail)
                                .font(.system(size: 12)).foregroundColor(T.gray)
                        }
                        .padding(.horizontal, 16).frame(height: 46)
                    }
                    .glassCard().padding(.horizontal, 18)

                    if !tip.isEmpty { Text(tip).font(.system(size: 11.5)).foregroundColor(T.gray) }
                    Text("改密码 / 退出登录在「我」那一页").font(.system(size: 11)).foregroundColor(T.gray)
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("我的资料")
        .navigationBarTitleDisplayMode(.inline)
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
    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            List {
                Section(header: Text("等我同意")) {
                    let incoming = store.reqs.filter { !$0.outgoing && $0.state == "pending" }
                    if incoming.isEmpty {
                        Text("没有新的申请").font(.system(size: 12.5)).foregroundColor(T.gray)
                    }
                    ForEach(incoming) { r in
                        HStack(spacing: 10) {
                            Ava(name: store.people[r.userId]?.display ?? "?", size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.people[r.userId]?.display ?? r.userId).font(.system(size: 13.5))
                                if !r.msg.isEmpty {
                                    Text(r.msg).font(.system(size: 11)).foregroundColor(T.gray)
                                }
                            }
                            Spacer()
                            Button("同意") { store.friendAck(from: r.userId, accept: true) }
                                .buttonStyle(.borderedProminent).tint(T.blue).controlSize(.small)
                            Button("拒绝") { store.friendAck(from: r.userId, accept: false) }
                                .buttonStyle(.bordered).controlSize(.small)
                        }
                        .padding(.vertical, 2)
                    }
                }
                Section(header: Text("我发出去的")) {
                    let out = store.reqs.filter { $0.outgoing }
                    if out.isEmpty {
                        Text("还没发过申请").font(.system(size: 12.5)).foregroundColor(T.gray)
                    }
                    ForEach(out) { r in
                        HStack(spacing: 10) {
                            Ava(name: store.people[r.userId]?.display ?? "?", size: 34)
                            Text(store.people[r.userId]?.display ?? r.userId).font(.system(size: 13))
                            Spacer()
                            Text(r.state == "accepted" ? "已同意" : (r.state == "rejected" ? "被拒绝" : "等对方同意"))
                                .font(.system(size: 11.5))
                                .foregroundColor(r.state == "accepted" ? T.green : T.gray)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("新的朋友")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/* ==================== 加好友（搜 BB鸡号） ==================== */
struct AddFriendView: View {
    @EnvironmentObject var store: Store
    @State private var q = ""
    @State private var tip = ""

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(T.gray)
                    TextField("输 BB鸡号 / 账号，先看看是谁", text: $q)
                        .font(.system(size: 13.5)).textInputAutocapitalization(.never).disableAutocorrection(true)
                }
                .padding(.horizontal, 12).frame(height: 42)
                .glassCard().padding(.horizontal, 18).padding(.top, 10)

                if let p = store.findUser(q) {
                    VStack(spacing: 10) {
                        Ava(name: p.display, size: 62, online: p.online)
                        Text(p.display).font(.system(size: 16, weight: .semibold)).foregroundColor(T.ink)
                        Text("BB鸡号 \(p.account)").font(.system(size: 11.5)).foregroundColor(T.gray)
                        if p.id == store.meUserId {
                            Text("这是你自己").font(.system(size: 12)).foregroundColor(T.gray)
                        } else if store.friends.contains(where: { $0.id == p.id }) {
                            Text("已经是好友了").font(.system(size: 12)).foregroundColor(T.green)
                        } else {
                            BigButton(title: "加好友") {
                                store.friendReq(to: p.id, msg: "")
                                tip = "申请发出了，等对方同意"
                            }
                            .padding(.horizontal, 40).padding(.top, 6)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    .glassCard().padding(.horizontal, 18)
                } else if !q.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("没找到这个账号 / BB鸡号\n检查一下有没有输错；对方也可能还没注册")
                        .font(.system(size: 12)).foregroundColor(T.gray)
                        .multilineTextAlignment(.center).padding(.top, 10)
                } else {
                    Text("输完整 BB鸡号，比如 xiangxiang").font(.system(size: 12)).foregroundColor(T.gray)
                        .padding(.top, 10)
                }
                if !tip.isEmpty { Text(tip).font(.system(size: 11.5)).foregroundColor(T.blue) }
                Spacer()
            }
        }
        .navigationTitle("加好友")
        .navigationBarTitleDisplayMode(.inline)
    }
}
