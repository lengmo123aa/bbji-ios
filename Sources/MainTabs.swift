import SwiftUI

/// M0 的三个 Tab 先摆骨架：消息 / 通讯录 / 我
/// 第三个 Tab 里放「设计稿」——用网页壳把我们已经画好的 55 屏直接显示出来，
/// 顺便验证"边缘页用网页"这条路在真机上通不通。
struct MainTabs: View {
    @EnvironmentObject var session: Session

    var body: some View {
        TabView {
            PlaceholderList(title: "消息", note: "M2 做真消息列表（未读 / 置顶 / 左滑）")
                .tabItem { Label("消息", systemImage: "bubble.left.and.bubble.right") }

            PlaceholderList(title: "通讯录", note: "M3 做通讯录 / 加好友 / 群")
                .tabItem { Label("通讯录", systemImage: "person.2") }

            MeTab().environmentObject(session)
                .tabItem { Label("我", systemImage: "person.crop.circle") }
        }
        .accentColor(Color(red: 0.29, green: 0.55, blue: 0.96))
    }
}

private struct PlaceholderList: View {
    let title: String
    let note: String
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Spacer()
                Text(title).font(.system(size: 22, weight: .semibold))
                Text(note).font(.system(size: 12.5)).foregroundColor(.gray)
                Spacer()
            }
            .navigationTitle(title)
        }
    }
}

private struct MeTab: View {
    @EnvironmentObject var session: Session
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 12) {
                        Circle().fill(Color.blue.opacity(0.15)).frame(width: 46, height: 46)
                            .overlay(Text(String(session.myName.prefix(1))).font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.myName.isEmpty ? "—" : session.myName).font(.system(size: 15, weight: .semibold))
                            Text("BB鸡号 \(session.myId)").font(.system(size: 11)).foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)

                    NavigationLink("设计稿（M0 验证用）") { WebShell() }
                }
                Section {
                    Button("退出登录", role: .destructive) { session.logout() }
                }
            }
            .navigationTitle("我")
        }
    }
}
