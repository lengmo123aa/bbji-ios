import SwiftUI

/// M0 的登录页：能连上 bbji.xkmd.cn、能登录、能记住登录态。
/// 样式按我们手机端设计稿的 iOS 去卡片基调来（蓝只占一点点、白底、大留白）。
struct LoginView: View {
    @EnvironmentObject var session: Session
    @State private var account = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.91, green: 0.95, blue: 0.99),
                                    Color(red: 0.96, green: 0.97, blue: 1.0),
                                    Color(red: 0.95, green: 0.94, blue: 0.99)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Color(red: 0.36, green: 0.69, blue: 1.0),
                                                      Color(red: 0.04, green: 0.39, blue: 0.78)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                        .overlay(Text("🔔").font(.system(size: 19)))
                    Text("BB鸡").font(.system(size: 26, weight: .bold))
                }
                .padding(.top, 60)

                Text("登录后开始聊天")
                    .font(.system(size: 13)).foregroundColor(.gray)
                    .padding(.top, 6)

                VStack(spacing: 0) {
                    field("邮箱 / BB鸡号", text: $account, secure: false)
                    Divider().padding(.leading, 14)
                    field("密码", text: $password, secure: true)
                }
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                .padding(.horizontal, 24)
                .padding(.top, 28)

                if !session.err.isEmpty {
                    Text(session.err)
                        .font(.system(size: 12)).foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 26).padding(.top, 10)
                }

                Button {
                    Task { await session.login(account: account.trimmingCharacters(in: .whitespaces),
                                               password: password) }
                } label: {
                    Text(session.busy ? "登录中…" : "登 录")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(LinearGradient(colors: [Color(red: 0.47, green: 0.69, blue: 1.0),
                                                            Color(red: 0.29, green: 0.55, blue: 0.96)],
                                                   startPoint: .top, endPoint: .bottom))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.blue.opacity(0.25), radius: 12, y: 6)
                }
                .disabled(session.busy)
                .padding(.horizontal, 24).padding(.top, 18)

                Spacer()
                Text("v0.0.1 · M0 链路验证").font(.system(size: 11)).foregroundColor(.gray.opacity(0.8))
                    .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func field(_ title: String, text: Binding<String>, secure: Bool) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 12.5)).foregroundColor(.gray).frame(width: 78, alignment: .leading)
            if secure {
                SecureField("", text: text).font(.system(size: 13.5))
            } else {
                TextField("", text: text).font(.system(size: 13.5))
                    .keyboardType(.emailAddress).autocapitalization(.none).disableAutocorrection(true)
            }
        }
        .padding(.horizontal, 14).frame(height: 50)
    }
}
