import SwiftUI

/* ==================== 30 群设置（成员 / 改群名 / 拉人 / 退出） ==================== */
struct GroupSettingsView: View {
    @EnvironmentObject var store: Store
    let gid: String
    @Environment(\.dismiss) private var dismiss
    @State private var renaming = false
    @State private var nameDraft = ""
    @State private var inviting = false
    @State private var picked: Set<String> = []
    @State private var tip = ""

    private var g: ChatGroup? { store.groupOf(gid) }
    private var members: [String] { g?.members ?? [] }

    var body: some View {
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                DZNavBar("群设置")   // 2026-10-07：自绘顶栏，别再走系统的（英文 Back + 灰底）
                ScrollView {
                VStack(spacing: 12) {
                    /* 群名片（左上横排，跟「我」「资料」一套） */
                    HStack(spacing: 14) {
                        Ava(name: g?.name ?? "群聊", size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(g?.name ?? "群聊").font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
                            Text("\(members.count) 人 · 群号 \(gid)").font(.system(size: 13)).foregroundColor(T.sec2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .glassCard(16).padding(.horizontal, 14)

                    /* 成员（点头像进资料页） */
                    VStack(alignment: .leading, spacing: 0) {
                        Text("群成员 · \(members.count)")
                            .font(.system(size: 13)).foregroundColor(T.sec2)
                            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 6)
                        ForEach(members, id: \.self) { id in
                            NavigationLink(destination: FriendProfileView(pid: id).environmentObject(store)) {
                                HStack(spacing: 12) {
                                    Ava(name: store.people[id]?.display ?? id, size: 42,
                                        online: store.people[id]?.online,
                                        img: store.people[id]?.avatar ?? "")
                                    Text(store.people[id]?.display ?? id).font(.system(size: 16)).foregroundColor(T.ink)
                                    if id == store.meUserId {
                                        Text("我").font(.system(size: 12)).foregroundColor(T.blue)
                                    }
                                    Spacer()
                                    Chev()
                                }
                                .padding(.horizontal, 14).frame(height: 58)
                            }
                        }
                    }
                    .glassCard(16).padding(.horizontal, 14)

                    /* 操作 */
                    VStack(spacing: 0) {
                        Button {
                            nameDraft = g?.name ?? ""; renaming = true
                        } label: {
                            SettingRow(title: "群名字", value: g?.name ?? "")
                        }
                        RowDivider()
                        Button { picked = []; inviting = true } label: {
                            HStack(spacing: 12) {
                                Text("邀请好友进群").font(.system(size: 16)).foregroundColor(T.ink)
                                Spacer(minLength: 0)
                                Chev()
                            }
                            .padding(.horizontal, 16).frame(height: 54)
                            .contentShape(Rectangle())
                        }
                    }
                    .glassCard(16).padding(.horizontal, 14)

                    VStack(spacing: 0) {
                        Button(role: .destructive) {
                            store.groupLeave(gid)
                            tip = "退出去了"
                            dismiss()
                        } label: {
                            Text("退出群聊").font(.system(size: 16))
                                .foregroundColor(T.red).frame(maxWidth: .infinity).frame(height: 54)
                        }
                    }
                    .glassCard(16).padding(.horizontal, 14)

                    if !tip.isEmpty { Text(tip).font(.system(size: 12.5)).foregroundColor(T.sec2) }
                    Text("只有群主 / 管理员能改群名、拉人；踢人暂时在电脑端做。")
                        .font(.system(size: 12)).foregroundColor(T.ter2)
                }
                .padding(.top, 6).padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("改群名", isPresented: $renaming) {
            TextField("群名（最多 20 字）", text: $nameDraft)
            Button("取消", role: .cancel) {}
            Button("保存") { store.groupRename(gid, name: nameDraft) }
        }
        .sheet(isPresented: $inviting) {
            InviteToGroupView(gid: gid).environmentObject(store)
        }
    }
}

/* ==================== 33 邀请进群（勾好友） ==================== */
struct InviteToGroupView: View {
    @EnvironmentObject var store: Store
    let gid: String
    @Environment(\.dismiss) private var dismiss
    @State private var picked: Set<String> = []

    private var candidates: [Person] {
        let inGroup = Set(store.groupOf(gid)?.members ?? [])
        return store.friends.filter { !inGroup.contains($0.id) }
    }

    var body: some View {
        /* 2026-10-07：从系统 List 改成自绘（跟别的页一套），顶上那颗「邀请」放在自绘导航栏右边 */
        ZStack {
            AppBg().ignoresSafeArea()
            VStack(spacing: 0) {
                DZNavBar(title: "邀请进群") {
                    Button {
                        H.tap()
                        store.groupInvite(gid, ids: Array(picked))
                        dismiss()
                    } label: {
                        Text(picked.isEmpty ? "邀请" : "邀请(\(picked.count))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(picked.isEmpty ? T.ter2 : T.blue)
                    }
                    .disabled(picked.isEmpty)
                }
                ScrollView {
                    VStack(spacing: 0) {
                        if candidates.isEmpty {
                            EmptyHint(icon: "person.2", text: "好友都已经在群里了")
                        }
                        ForEach(candidates) { f in
                            Button {
                                H.sel()
                                if picked.contains(f.id) { picked.remove(f.id) } else { picked.insert(f.id) }
                            } label: {
                                HStack(spacing: 12) {
                                    Ava(name: f.display, size: 42, online: f.online, img: f.avatar)
                                    Text(f.display).font(.system(size: 16)).foregroundColor(T.ink)
                                    Spacer(minLength: 0)
                                    Image(systemName: picked.contains(f.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(picked.contains(f.id) ? T.blue : T.ter2)
                                }
                                .padding(.horizontal, 14).frame(height: 58)
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
                    .glassCard(16).padding(.horizontal, 14).padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
