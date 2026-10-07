import SwiftUI
import UIKit

/* ==================================================================
   Theme —— 数值全部照 v5 设计稿（含 v3「质感层」那一档覆盖）抄，别自己发明。
   对应 mobile-ui.html 里的 CSS 变量与规则：
     --blue #4A8BF6 / --ink #0B0D12 / --sec #93A0B0 / --ter #BEC6D2
     --sep rgba(60,60,67,.045) / 页面背景 168deg #E9F1FD→#F5F9FE→#F2EFFC + 两个柔光球
   ================================================================== */
enum T {
    /* ⚠️ 关键：效果图那套 HTML 是按 **270pt 宽**的画框画的（mobile-ui.html 里 .scr{width:270px}），
       真机 iPhone 是 **393pt 宽** → 直接把效果图的 14px 名字搬到手机上就"小一圈、扁一圈"。
       所有从效果图抄来的数值都要乘这个 k（393/270 ≈ 1.455）。以后加新页面也照这个来。 */
    static let k: CGFloat = 393.0 / 270.0

    /* 文字 */
    static let ink = Color(red: 0.043, green: 0.051, blue: 0.071)      // #0B0D12
    static let ink2 = Color(red: 0.173, green: 0.196, blue: 0.235)     // #2C323C
    static let sub = Color(red: 0.44, green: 0.50, blue: 0.56)
    static let gray = Color(red: 0.54, green: 0.58, blue: 0.64)
    static let sec2 = Color(red: 0.576, green: 0.627, blue: 0.690)     // #93A0B0
    static let ter2 = Color(red: 0.745, green: 0.776, blue: 0.824)     // #BEC6D2
    static let tabIdle = Color(red: 0.643, green: 0.675, blue: 0.722)  // #A4ACB8
    static let hint = Color(red: 0.596, green: 0.631, blue: 0.682)     // #98A1AE
    static let line = Color(red: 0.88, green: 0.90, blue: 0.93)

    /* 主色 / 状态色 */
    static let blue = Color(red: 0.290, green: 0.545, blue: 0.965)     // #4A8BF6
    static let blueDeep = Color(red: 0.239, green: 0.482, blue: 0.910) // #3D7BE8
    static let blueLight = Color(red: 0.475, green: 0.690, blue: 1.0)  // #79B0FF
    static let green = Color(red: 0.204, green: 0.780, blue: 0.349)    // #34C759
    static let red = Color(red: 0.941, green: 0.275, blue: 0.227)      // #F0463A

    static let sep = Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.045)
    static let sepLine = sep
    static let pinBg = Color(red: 0.416, green: 0.659, blue: 1.0).opacity(0.10)   // .li.pin
    static let rowSolid = Color(red: 0.976, green: 0.988, blue: 1.0)             // 左滑时行的底（盖住按钮用）
    static let cardRadius: CGFloat = 34

    /* 渐变（v3：按钮/气泡/角标都换成了浅蓝→蓝、浅红→红） */
    static let gradBlue = LinearGradient(
        colors: [Color(red: 0.443, green: 0.671, blue: 1.0),          // #71ABFF
                 Color(red: 0.290, green: 0.545, blue: 0.965)],        // #4A8BF6
        startPoint: .top, endPoint: .bottom)
    static let gradRed = LinearGradient(
        colors: [Color(red: 1.0, green: 0.420, blue: 0.357),          // #FF6B5B
                 Color(red: 0.941, green: 0.275, blue: 0.227)],        // #F0463A
        startPoint: .top, endPoint: .bottom)
    static let gradGreen = LinearGradient(
        colors: [Color(red: 0.373, green: 0.851, blue: 0.494),        // #5FD97E
                 Color(red: 0.204, green: 0.780, blue: 0.349)],        // #34C759
        startPoint: .top, endPoint: .bottom)
    static let gradSwipeGray = LinearGradient(
        colors: [Color(red: 0.780, green: 0.812, blue: 0.859),
                 Color(red: 0.741, green: 0.776, blue: 0.831)],
        startPoint: .top, endPoint: .bottom)
    static let gradOrange = LinearGradient(
        colors: [Color(red: 0.945, green: 0.596, blue: 0.267),
                 Color(red: 0.918, green: 0.522, blue: 0.196)],
        startPoint: .top, endPoint: .bottom)

    /// 页面背景（v3：168deg 三段渐变）
    static let bg = LinearGradient(
        stops: [.init(color: Color(red: 0.914, green: 0.945, blue: 0.992), location: 0),
                .init(color: Color(red: 0.961, green: 0.976, blue: 0.996), location: 0.44),
                .init(color: Color(red: 0.949, green: 0.937, blue: 0.988), location: 1)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 字头兜底头像用的渐变（照 v3 那 6 组图标底色）
    static let avGrads: [[Color]] = [
        [Color(red: 0.498, green: 0.714, blue: 1.0), Color(red: 0.290, green: 0.545, blue: 0.965)],
        [Color(red: 1.0, green: 0.663, blue: 0.769), Color(red: 0.949, green: 0.333, blue: 0.490)],
        [Color(red: 0.776, green: 0.663, blue: 1.0), Color(red: 0.557, green: 0.420, blue: 0.941)],
        [Color(red: 1.0, green: 0.757, blue: 0.510), Color(red: 0.941, green: 0.569, blue: 0.247)],
        [Color(red: 0.561, green: 0.890, blue: 0.690), Color(red: 0.220, green: 0.698, blue: 0.416)],
        [Color(red: 0.561, green: 0.867, blue: 0.910), Color(red: 0.180, green: 0.624, blue: 0.698)],
    ]
}

/* ==================== 触感（原生三层里最容易被忽略、但最"贵"的一层） ==================== */
enum H {
    static func tap(_ s: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let g = UIImpactFeedbackGenerator(style: s)
        g.prepare()
        g.impactOccurred()
    }
    static func sel() { UISelectionFeedbackGenerator().selectionChanged() }
    static func ok() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warn() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

/* ==================== 附件地址 / 图片缓存 ====================
   两个真机 bug 的根：
   ① /api/file/<id> 必须带 ?t=<token>，不然 401（头像/聊天图都出不来）；
   ② AsyncImage 不缓存，列表一滚就重新下载 → 头像一闪一闪，看着就廉价。
   ============================================================ */
func bbFileURL(_ fid: String) -> URL? {
    let f = fid.trimmingCharacters(in: .whitespacesAndNewlines)
    if f.isEmpty { return nil }
    if f.hasPrefix("http") { return URL(string: f) }
    let t = (UserDefaults.standard.string(forKey: "bbji_token") ?? "")
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return URL(string: "https://bbji.xkmd.cn/api/file/\(f)?t=\(t)")
}

/// 当前装的到底是哪一版（0.0.2 (3) 这样）—— 界面上写出来，省得"装上了没"靠猜
func appVersionText() -> String {
    let i = Bundle.main.infoDictionary
    let v = (i?["CFBundleShortVersionString"] as? String) ?? "?"
    let b = (i?["CFBundleVersion"] as? String) ?? "?"
    return v + " (" + b + ")"
}

final class ImgStore {
    static let shared = ImgStore()
    private let cache = NSCache<NSURL, UIImage>()
    private init() { cache.countLimit = 240 }
    func cached(_ u: URL) -> UIImage? { cache.object(forKey: u as NSURL) }
    func image(_ u: URL) async -> UIImage? {
        if let i = cached(u) { return i }
        guard let (d, _) = try? await URLSession.shared.data(from: u),
              let i = UIImage(data: d) else { return nil }
        cache.setObject(i, forKey: u as NSURL)
        return i
    }
}

/// 带缓存的网络图（没有就用灰底占位）
struct NetImg: View {
    let url: URL?
    var fill: Bool = true
    /// true = 还没加载出来（或者加载失败）时留空，让底下那层（字母头像）露出来。
    /// 头像必须用这个：不然 QQ 头像一取不到，就变成一个灰疙瘩，比没有还难看。
    var ghost: Bool = false
    @State private var img: UIImage?

    var body: some View {
        Group {
            if let img {
                Image(uiImage: img).resizable()
                    .aspectRatio(contentMode: fill ? .fill : .fit)
            } else if ghost {
                Color.clear
            } else {
                Color(red: 0.906, green: 0.921, blue: 0.945)
            }
        }
        .onAppear { load() }
        .onChange(of: url) { _ in img = nil; load() }
    }

    private func load() {
        guard let url else { return }
        if let c = ImgStore.shared.cached(url) { img = c; return }
        Task { @MainActor in
            if let i = await ImgStore.shared.image(url) { img = i }
        }
    }
}

/// 通用按压反馈（所有能点的行/按钮都挂它，手指才不会觉得"点了没反应"）
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.94
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    /// 那层半透明白卡（跟设计稿里 .grp / .card 一样）
    func glassCard(_ radius: CGFloat = T.cardRadius) -> some View {
        background(.ultraThinMaterial)
            .background(Color.white.opacity(0.50))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.05), radius: 13, y: 5)
    }
}

/// 页面背景：168deg 三段渐变 + 左上蓝光球 + 右侧紫光球（v3 的"空气感"）
struct AppBg: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                T.bg
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.494, green: 0.690, blue: 1.0).opacity(0.50),
                                 Color(red: 0.494, green: 0.690, blue: 1.0).opacity(0.0)],
                        center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: 300, height: 300)
                    .position(x: 55, y: 35)
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.729, green: 0.651, blue: 1.0).opacity(0.42),
                                 Color(red: 0.729, green: 0.651, blue: 1.0).opacity(0.0)],
                        center: .center, startRadius: 0, endRadius: 140))
                    .frame(width: 280, height: 280)
                    .position(x: g.size.width - 36, y: 272)
            }
        }
        .ignoresSafeArea()
    }
}

/// 官方 logo（图标资源，1024 那张圆的）
struct LogoMark: View {
    var size: CGFloat
    var body: some View {
        Image("Logo").resizable().interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}

/// 主按钮：跟设计稿一样的蓝色胶囊
struct BigButton: View {
    let title: String
    var busy = false
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(busy ? "请稍等…" : title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(LinearGradient(colors: [T.blueLight, T.blue], startPoint: .top, endPoint: .bottom))
                .clipShape(Capsule())
                .shadow(color: T.blue.opacity(0.25), radius: 12, y: 6)
                .opacity(disabled || busy ? 0.55 : 1)
        }
        .disabled(disabled || busy)
    }
}

/// 表单里的一行：左边标签、右边输入框（设计稿里的 .row tall）
struct FieldRow: View {
    let label: String
    @Binding var text: String
    var placeholder = ""
    var secure = false
    var keyboard: UIKeyboardType = .default
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12.5)).foregroundColor(T.gray)
                .frame(width: 74, alignment: .leading)
            if secure {
                SecureField(placeholder, text: $text).font(.system(size: 13.5))
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text).font(.system(size: 13.5))
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            if let t = trailing { t }
        }
        .padding(.horizontal, 14).frame(height: 48)
    }
}

/// 设置那种一行：左标题 + 小字说明 + 右边箭头（后面 M2 直接拿来用）
struct RowLine: View {
    let title: String
    var note: String = ""
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12.5, weight: .semibold)).foregroundColor(T.ink)
                if !note.isEmpty { Text(note).font(.system(size: 10.5)).foregroundColor(T.gray) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.79, green: 0.82, blue: 0.85))
        }
        .padding(.horizontal, 14).frame(minHeight: 44)
    }
}

/// 大标题（效果图 .ltitle h1：25px / 700 / 字距 -0.9）
/* ==================== 统一的自绘导航栏（2026-10-07 用户截图反馈）====================
   以前 新的朋友 / 加好友 / 我的资料 / 好友资料 用系统的 .navigationTitle，
   结果：① 左上角是**英文 Back**（App 没做中文本地化），很掉价；
        ② 系统导航栏 + 系统灰底 #F2F2F7 跟自绘的玻璃/渐变两套风格，一进就像换了个 App。
   现在统一用它：左 ‹ 返回 + 居中标题（真机 iOS 顶栏 17pt semibold），高 50。 */
struct DZNavBar<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing
    @Environment(\.presentationMode) private var pm
    var body: some View {
        HStack(spacing: 8) {
            Button {
                H.tap()
                pm.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(T.blue)
                    .frame(width: 34, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressStyle(scale: 0.86))
            Spacer(minLength: 0)
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(T.ink)
            Spacer(minLength: 0)
            trailing().frame(width: 34, height: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16).frame(height: 50)
    }
}
extension DZNavBar where Trailing == EmptyView {
    init(_ title: String) { self.init(title: title) { EmptyView() } }
}

/// 小块标题（「等我同意」这种）
struct SecLabel: View {
    let text: String
    var body: some View {
        HStack {
            Text(text).font(.system(size: 13)).foregroundColor(T.sec2)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.bottom, 7).padding(.top, 4)
    }
}

/// 空状态（别再让半屏大白）—— 一个淡图标 + 一句人话
struct EmptyHint: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light)).foregroundColor(T.ter2)
            Text(text).font(.system(size: 13)).foregroundColor(T.sec2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 30)
    }
}

/// 自绘小胶囊按钮（同意 / 拒绝 / 加好友 这种页内按钮）
struct PillBtn: View {
    let title: String
    var kind: Kind = .blue
    let action: () -> Void
    enum Kind { case blue, gray, red }
    private var bg: AnyShapeStyle {
        switch kind {
        case .blue: return AnyShapeStyle(T.gradBlue)
        case .red: return AnyShapeStyle(T.gradRed)
        case .gray: return AnyShapeStyle(Color.white.opacity(0.85))
        }
    }
    private var fg: Color { kind == .gray ? T.ink2 : .white }
    var body: some View {
        Button { H.tap(); action() } label: {
            Text(title)
                .font(.system(size: 13.5, weight: .semibold)).foregroundColor(fg)
                .padding(.horizontal, 16).frame(height: 32)
                .background(bg)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(kind == .gray ? T.line : Color.clear, lineWidth: 0.5))
        }
        .buttonStyle(PressStyle(scale: 0.93))
    }
}

/* 2026-10-07（用户真机截图反馈）：效果图是按 270pt 画框画的，×1.455 是"等比放大"，
   但真机 iOS 的大标题就是 **34pt**（微信 34 / 系统 Large Title 34）。×1.455 得到的 36.4 偏大，
   而且字距 -1.2 在中文字上显得挤。这里直接改用真机数值。 */
struct TopTitle<Trailing: View>: View {
    let text: String
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(text).font(.system(size: 34, weight: .bold))
                .kerning(-0.6).foregroundColor(T.ink)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 10)
    }
}
extension TopTitle where Trailing == EmptyView {
    init(_ text: String) { self.init(text: text) { EmptyView() } }
}

/// 搜索框（v3 的 .srch：高 34 / 圆角 15 / 玻璃 + 白 58% / 12px —— 全部 ×k）
/* 同上：改成真机数值（高 38 / 圆角 11 / 字 15），×1.455 那版 49 高 + 胶囊圆角在真机上太大太圆 */
struct SearchBar: View {
    let placeholder: String
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.68))
            Text(placeholder).font(.system(size: 15)).foregroundColor(T.hint)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).frame(height: 38)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
            .stroke(Color.white.opacity(0.60), lineWidth: 0.5))
        .shadow(color: Color(red: 0.063, green: 0.125, blue: 0.25).opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal, 16).padding(.bottom, 12)
    }
}

/// 红点数字（v3 的 .bdg：min 18 / 圆角 9 / #FF6B5B→#F0463A / 11px / 带投影）
struct BadgeNum: View {
    let n: Int
    var body: some View {
        Text(n > 99 ? "99+" : "\(n)")
            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            .padding(.horizontal, 7).frame(minWidth: 26, minHeight: 26)
            .background(T.gradRed)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .shadow(color: Color(red: 0.941, green: 0.275, blue: 0.227).opacity(0.35), radius: 1.5, y: 1)
    }
}

/// 底部标签栏（v3 的 .tab：高 62 / 白 55% + 模糊 18 / 顶线 .5 / 9px / 选中蓝）
struct DZTabBar: View {
    @Binding var sel: Int
    private let items: [(String, String, String)] = [
        ("bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill", "消息"),
        ("person.2", "person.2.fill", "通讯录"),
        ("person.crop.circle", "person.crop.circle.fill", "我"),
    ]
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(T.sep).frame(height: 0.5)
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    Button {
                        guard sel != i else { return }
                        H.sel()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { sel = i }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: sel == i ? items[i].1 : items[i].0)
                                .font(.system(size: 23, weight: .regular))
                                .scaleEffect(sel == i ? 1.0 : 0.94)
                            Text(items[i].2).font(.system(size: 10.5, weight: sel == i ? .medium : .regular))
                        }
                        .foregroundColor(sel == i ? T.blue : T.tabIdle)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressStyle(scale: 0.92))
                }
            }
            .padding(.top, 7).frame(height: 58, alignment: .top)
        }
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color.white.opacity(0.55))
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// 头像（设计稿：图 + 右下角绿点；不在线的头像整体去色 + 透明度 55%）
struct Ava: View {
    let name: String
    var size: CGFloat = 46
    var online: Bool? = nil
    var img: String = ""
    private var u: URL? { bbFileURL(img) }
    private var pick: Int {
        var h = 0
        for c in name.unicodeScalars { h = (h &* 31 &+ Int(c.value)) % 9973 }
        return h % T.avGrads.count
    }
    private var dot: CGFloat { max(9, size * 0.24) }
    private var grad: LinearGradient {
        LinearGradient(colors: T.avGrads[pick], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(grad)
                Text(String(name.prefix(1)))
                    .font(.system(size: size * 0.40, weight: .semibold))
                    .foregroundColor(.white)
                if u != nil {
                    NetImg(url: u, ghost: true).frame(width: size, height: size)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 0.5))
            /* 2026-10-07（截图反馈）：离线不再把整个头像去色 + 变半透明 ——
               一半好友是灰疙瘩，混在一起看着脏。微信只把在线绿点去掉。 */
            if online == true {
                Circle().fill(T.gradGreen).frame(width: dot, height: dot)
                    .overlay(Circle().stroke(Color.white.opacity(0.95), lineWidth: 2))
                    .offset(x: 0.5, y: 0.5)
            }
        }
        .frame(width: size, height: size)
    }
}
