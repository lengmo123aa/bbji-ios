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
            ScrollView {
                VStack(spacing: 12) {
                    /* 群名片 */
                    VStack(spacing: 8) {
                        Ava(name: g?.name ?? "群聊", size: 76)
                        Text(g?.name ?? "群聊").font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
                        Text("\(members.count) 人 · 群号 \(gid)").font(.system(size: 11)).foregroundColor(T.gray)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    .glassCard().padding(.horizontal, 18)

                    /* 成员（点头像进资料页） */
                    VStack(alignment: .leading, spacing: 0) {
                        Text("群成员 · \(members.count)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(T.gray)
                            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 6)
                        ForEach(members, id: \.self) { id in
                            NavigationLink(destination: FriendProfileView(pid: id).environmentObject(store)) {
                                HStack(spacing: 10) {
                                    Ava(name: store.people[id]?.display ?? id, size: 34,
                                        online: store.people[id]?.online)
                                    Text(store.people[id]?.display ?? id).font(.system(size: 13.5))
                                    if id == store.meUserId {
                                        Text("我").font(.system(size: 10)).foregroundColor(T.blue)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(Color(red: 0.79, green: 0.82, blue: 0.85))
                                }
                                .padding(.horizontal, 16).frame(height: 44)
                            }
                        }
                    }
                    .glassCard().padding(.horizontal, 18)

                    /* 操作 */
                    VStack(spacing: 0) {
                        Button {
                            nameDraft = g?.name ?? ""; renaming = true
                        } label: {
                            HStack { Text("群名字").font(.system(size: 13.5)).foregroundColor(T.ink)
                                Spacer()
                                Text(g?.name ?? "").font(.system(size: 12)).foregroundColor(T.gray) }
                                .padding(.horizontal, 16).frame(height: 46)
                        }
                        Divider().opacity(0.5)
                        Button { picked = []; inviting = true } label: {
                            HStack { Text("邀请好友进群").font(.system(size: 13.5)).foregroundColor(T.ink)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.79, green: 0.82, blue: 0.85)) }
                                .padding(.horizontal, 16).frame(height: 46)
                        }
                    }
                    .glassCard().padding(.horizontal, 18)

                    VStack(spacing: 0) {
                        Button(role: .destructive) {
                            store.groupLeave(gid)
                            tip = "退出去了"
                            dismiss()
                        } label: {
                            Text("退出群聊").font(.system(size: 13.5))
                                .foregroundColor(T.red).frame(maxWidth: .infinity).frame(height: 46)
                        }
                    }
                    .glassCard().padding(.horizontal, 18)

                    if !tip.isEmpty { Text(tip).font(.system(size: 11.5)).foregroundColor(T.gray) }
                    Text("只有群主 / 管理员能改群名、拉人；踢人暂时在电脑端做。")
                        .font(.system(size: 11)).foregroundColor(T.gray)
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("群设置")
        .navigationBarTitleDisplayMode(.inline)
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
        NavigationView {
            List {
                if candidates.isEmpty {
                    Text("好友都已经在群里了").font(.system(size: 12.5)).foregroundColor(T.gray)
                }
                ForEach(candidates) { f in
                    Button {
                        if picked.contains(f.id) { picked.remove(f.id) } else { picked.insert(f.id) }
                    } label: {
                        HStack(spacing: 10) {
                            Ava(name: f.display, size: 34, online: f.online)
                            Text(f.display).font(.system(size: 13.5)).foregroundColor(T.ink)
                            Spacer()
                            Image(systemName: picked.contains(f.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(picked.contains(f.id) ? T.blue : Color(red: 0.79, green: 0.82, blue: 0.85))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("邀请进群")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("邀请(\(picked.count))") {
                        store.groupInvite(gid, ids: Array(picked))
                        dismiss()
                    }
                    .disabled(picked.isEmpty)
                }
            }
        }
    }
}
