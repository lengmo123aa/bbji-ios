import SwiftUI

/// 没登录之前的那几屏（照设计稿 v5 的 01–05 做的，全是原生 SwiftUI）：
/// 01 启动页 → 02 登录 → 03 注册 → 04 取名字 / 05 找回密码。
enum AuthRoute { case splash, login, register, nickname, forgot }

struct AuthFlow: View {
    @EnvironmentObject var session: Session
    @AppStorage("bbji_splash_done") private var splashDone = false
    @State private var route: AuthRoute = .splash

    var body: some View {
        ZStack {
            AppBg()
            switch route {
            case .splash:
                SplashScreen {
                    splashDone = true
                    route = .login
                }
            case .login:
                LoginScreen(goRegister: { route = .register }, goForgot: { route = .forgot })
            case .register:
                RegisterScreen(back: { route = .login }, done: { route = .nickname })
            case .nickname:
                NicknameScreen()
            case .forgot:
                ForgotScreen(back: { route = .login })
            }
        }
        .preferredColorScheme(.light)
        .onAppear { if splashDone { route = .login } }
    }
}

/* ==================== 01 启动页 ==================== */
private struct SplashScreen: View {
    let go: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 9) {
                LogoMark(size: 70)
                Text("BB鸡").font(.system(size: 23, weight: .bold)).foregroundColor(T.ink)
            }
            .padding(.top, 46)

            Text("随时随地\n与重要的人聊天")
                .font(.system(size: 13)).foregroundColor(T.sub)
                .multilineTextAlignment(.center).lineSpacing(4)
                .padding(.top, 16)
            Text("更简洁 · 更流畅 · 更懂你")
                .font(.system(size: 11)).foregroundColor(Color(red: 0.68, green: 0.71, blue: 0.76))
                .padding(.top, 12)

            Spacer()

            BigButton(title: "开始使用", action: go).padding(.horizontal, 26)
            Button(action: go) {
                Text("已有账号，去登录").font(.system(size: 13)).foregroundColor(T.blue)
            }
            .padding(.top, 14).padding(.bottom, 30)
        }
    }
}

/* ==================== 02 登录 ==================== */
struct LoginScreen: View {
    @EnvironmentObject var session: Session
    let goRegister: () -> Void
    let goForgot: () -> Void
    @State private var account = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 9) {
                    LogoMark(size: 62)
                    Text("BB鸡").font(.system(size: 23, weight: .bold)).foregroundColor(T.ink)
                }
                .padding(.top, 54)
                Text("登录后开始聊天").font(.system(size: 12.5)).foregroundColor(T.sub).padding(.top, 6)

                VStack(spacing: 0) {
                    FieldRow(label: "邮箱", text: $account, placeholder: "邮箱 / BB鸡号", keyboard: .emailAddress)
                    Divider().padding(.leading, 14).opacity(0.5)
                    FieldRow(label: "密码", text: $password, placeholder: "密码", secure: true)
                }
                .glassCard()
                .padding(.horizontal, 24).padding(.top, 26)

                if !session.err.isEmpty {
                    Text(session.err).font(.system(size: 12)).foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28).padding(.top, 10)
                }

                BigButton(title: "登 录", busy: session.busy, disabled: account.isEmpty || password.isEmpty) {
                    Task { await session.login(account: account, password: password) }
                }
                .padding(.horizontal, 24).padding(.top, 16)

                Button(action: goForgot) {
                    Text("忘记密码？").font(.system(size: 13)).foregroundColor(T.blue)
                }
                .padding(.top, 14)

                Spacer(minLength: 40)
                HStack(spacing: 2) {
                    Text("还没有账号？").font(.system(size: 11)).foregroundColor(Color(red: 0.68, green: 0.71, blue: 0.76))
                    Button(action: goRegister) {
                        Text("去注册").font(.system(size: 11, weight: .medium)).foregroundColor(T.blue)
                    }
                }
                .padding(.bottom, 26)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 40)
        }
    }
}

/* ==================== 03 注册 ==================== */
struct RegisterScreen: View {
    @EnvironmentObject var session: Session
    let back: () -> Void
    let done: () -> Void
    @State private var account = ""
    @State private var email = ""
    @State private var code = ""
    @State private var password = ""
    @State private var tip = ""
    @State private var left = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: back) {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(T.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 8)

                VStack(spacing: 9) {
                    LogoMark(size: 56)
                    Text("注册 BB鸡").font(.system(size: 21, weight: .bold)).foregroundColor(T.ink)
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    FieldRow(label: "账号", text: $account, placeholder: "3-20 位，字母数字下划线")
                    Divider().padding(.leading, 14).opacity(0.5)
                    FieldRow(label: "邮箱", text: $email, placeholder: "用于接收验证码", keyboard: .emailAddress)
                    Divider().padding(.leading, 14).opacity(0.5)
                    FieldRow(label: "验证码", text: $code, placeholder: "6 位数字", keyboard: .numberPad,
                             trailing: AnyView(codeButton))
                    Divider().padding(.leading, 14).opacity(0.5)
                    FieldRow(label: "密码", text: $password, placeholder: "至少 6 位", secure: true)
                }
                .glassCard()
                .padding(.horizontal, 22).padding(.top, 22)

                if !tip.isEmpty {
                    Text(tip).font(.system(size: 11.5))
                        .foregroundColor(tip.hasPrefix("✅") ? T.green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 26).padding(.top, 10)
                }
                Text("验证码 5 分钟内有效；收不到看下垃圾箱。")
                    .font(.system(size: 11)).foregroundColor(T.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 26).padding(.top, 8)

                Spacer(minLength: 30)
                BigButton(title: "注册", busy: session.busy,
                          disabled: account.isEmpty || email.isEmpty || code.isEmpty || password.isEmpty) {
                    Task {
                        let e = await session.register(account: account, email: email, code: code, password: password)
                        if e.isEmpty { done() } else { tip = e }
                    }
                }
                .padding(.horizontal, 22).padding(.bottom, 26)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 40)
        }
    }

    private var codeButton: some View {
        Button {
            Task {
                let e = await session.sendCode(email, scene: "register")
                if e.isEmpty {
                    tip = "✅ 验证码已发到 \(email)"
                    left = 60
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
                        left -= 1
                        if left <= 0 { t.invalidate() }
                    }
                } else { tip = e }
            }
        } label: {
            Text(left > 0 ? "\(left) 秒后重发" : "获取验证码")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(left > 0 ? T.gray : T.blue)
        }
        .disabled(left > 0)
    }
}

/* ==================== 04 取名字 ==================== */
struct NicknameScreen: View {
    @EnvironmentObject var session: Session
    @State private var name = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("取个名字").font(.system(size: 15, weight: .semibold)).foregroundColor(T.ink)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 12)

            ZStack {
                Circle().fill(LinearGradient(colors: [T.blueLight, T.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                Text(String((name.isEmpty ? session.myName : name).prefix(1)))
                    .font(.system(size: 32, weight: .bold)).foregroundColor(.white)
            }
            .padding(.top, 26)
            Text("点头像可以换一张").font(.system(size: 12)).foregroundColor(T.sub).padding(.top, 12)

            VStack(spacing: 0) {
                FieldRow(label: "昵称", text: $name, placeholder: session.myName)
            }
            .glassCard()
            .padding(.horizontal, 22).padding(.top, 20)

            Text("以后在「我 → 我的资料」里随时能改。")
                .font(.system(size: 11)).foregroundColor(T.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 26).padding(.top, 10)

            Spacer()
            BigButton(title: "进入 BB鸡") {
                Task { _ = await session.setNickname(name) }
            }
            .padding(.horizontal, 22).padding(.bottom, 26)
        }
        .onAppear { if name.isEmpty { name = session.myName } }
    }
}

/* ==================== 05 找回密码 ==================== */
struct ForgotScreen: View {
    @EnvironmentObject var session: Session
    let back: () -> Void
    @State private var email = ""
    @State private var code = ""
    @State private var password = ""
    @State private var tip = ""
    @State private var left = 0
    @State private var timer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: back) {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(T.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 8)

                Text("找回密码").font(.system(size: 16, weight: .semibold)).foregroundColor(T.ink)
                    .padding(.top, 4)

                VStack(spacing: 0) {
                    FieldRow(label: "邮箱", text: $email, placeholder: "注册时用的邮箱", keyboard: .emailAddress)
                    Divider().padding(.leading, 14).opacity(0.5)
                    FieldRow(label: "验证码", text: $code, placeholder: "6 位数字", keyboard: .numberPad,
                             trailing: AnyView(codeButton))
                    Divider().padding(.leading, 14).opacity(0.5)
                    FieldRow(label: "新密码", text: $password, placeholder: "至少 6 位", secure: true)
                }
                .glassCard()
                .padding(.horizontal, 22).padding(.top, 20)

                if !tip.isEmpty {
                    Text(tip).font(.system(size: 11.5))
                        .foregroundColor(tip.hasPrefix("✅") ? T.green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 26).padding(.top, 10)
                }
                Text("验证码 5 分钟内有效；改完用新密码登录。")
                    .font(.system(size: 11)).foregroundColor(T.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 26).padding(.top, 8)

                Spacer(minLength: 30)
                BigButton(title: "重设密码", busy: session.busy, disabled: email.isEmpty || code.isEmpty || password.isEmpty) {
                    Task {
                        let e = await session.resetPassword(email: email, code: code, password: password)
                        if e.isEmpty { back() } else { tip = e }
                    }
                }
                .padding(.horizontal, 22).padding(.bottom, 26)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 40)
        }
    }

    private var codeButton: some View {
        Button {
            Task {
                let e = await session.sendCode(email, scene: "reset")
                if e.isEmpty {
                    tip = "✅ 验证码已发到 \(email)"
                    left = 60
                    timer?.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
                        left -= 1
                        if left <= 0 { t.invalidate() }
                    }
                } else { tip = e }
            }
        } label: {
            Text(left > 0 ? "\(left) 秒后重发" : "获取验证码")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(left > 0 ? T.gray : T.blue)
        }
        .disabled(left > 0)
    }
}
