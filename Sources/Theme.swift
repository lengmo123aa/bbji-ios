import SwiftUI

/// 手机端设计稿（v5 全套）里的那套色 / 尺寸，集中放这儿，别处不要再写死颜色。
enum T {
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.19)         // #1A2130
    static let sub = Color(red: 0.44, green: 0.50, blue: 0.56)         // #71798A
    static let gray = Color(red: 0.54, green: 0.58, blue: 0.64)
    static let line = Color(red: 0.88, green: 0.90, blue: 0.93)
    static let blue = Color(red: 0.29, green: 0.55, blue: 0.96)        // #4A8BF6
    static let blueLight = Color(red: 0.47, green: 0.69, blue: 1.0)    // #79B0FF
    static let green = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let red = Color(red: 0.95, green: 0.23, blue: 0.19)
    static let cardRadius: CGFloat = 14
    static let bg = LinearGradient(
        colors: [Color(red: 0.914, green: 0.945, blue: 0.992),
                 Color(red: 0.961, green: 0.976, blue: 0.996),
                 Color(red: 0.949, green: 0.937, blue: 0.988)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension View {
    /// 那层半透明白卡（跟设计稿里 .grp / .card 一样）
    func glassCard(_ radius: CGFloat = T.cardRadius) -> some View {
        background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

struct AppBg: View {
    var body: some View { T.bg.ignoresSafeArea() }
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

/* ==================================================================
   0.0.3：按 v5 效果图的 CSS 数值，把界面层全部自绘（不再用系统 List / 导航栏 / 标签栏）
   —— 效果图里的数值搬过来，别自己发明。
   ================================================================== */
extension T {
    static let ink2 = Color(red: 0.063, green: 0.090, blue: 0.145)     // #101725
    static let sec2 = Color(red: 0.541, green: 0.576, blue: 0.627)     // #8A93A0
    static let ter2 = Color(red: 0.706, green: 0.745, blue: 0.796)     // #B4BECB
    static let tabIdle = Color(red: 0.643, green: 0.675, blue: 0.722)  // #A4ACB8
    static let sepLine = Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.05)
    static let gradBlue = LinearGradient(colors: [Color(red: 0.475, green: 0.690, blue: 1.0),
                                                  Color(red: 0.290, green: 0.545, blue: 0.965)],
                                         startPoint: .top, endPoint: .bottom)
    static let gradRed = LinearGradient(colors: [Color(red: 1.0, green: 0.420, blue: 0.357),
                                                 Color(red: 0.941, green: 0.275, blue: 0.227)],
                                        startPoint: .top, endPoint: .bottom)
}

/// 大标题（效果图 .ltitle h1：25px / 700 / 字距 -0.9）
struct TopTitle<Trailing: View>: View {
    let text: String
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(text).font(.system(size: 25, weight: .bold))
                .kerning(-0.9).foregroundColor(T.ink)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 18).padding(.top, 2).padding(.bottom, 12)
    }
}
extension TopTitle where Trailing == EmptyView {
    init(_ text: String) { self.init(text: text) { EmptyView() } }
}

/// 搜索框（效果图 .srch：高 34 / 圆角 11 / 12px / #98A1AE）
struct SearchBar: View {
    let placeholder: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 13))
                .foregroundColor(Color(red: 0.60, green: 0.63, blue: 0.68))
            Text(placeholder).font(.system(size: 12)).foregroundColor(Color(red: 0.596, green: 0.631, blue: 0.682))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10).frame(height: 34)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .padding(.horizontal, 14).padding(.bottom, 10)
    }
}

/// 红点数字（效果图 .bdg：min 18 / 圆角 9 / 红渐变 / 11px）
struct BadgeNum: View {
    let n: Int
    var body: some View {
        Text("\(n)")
            .font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
            .padding(.horizontal, 5).frame(minWidth: 18, minHeight: 18)
            .background(T.gradRed)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .shadow(color: Color(red: 0.94, green: 0.27, blue: 0.23).opacity(0.35), radius: 1.5, y: 1)
    }
}

/// 底部标签栏（效果图 .tab：高 62 / 白 55% + 模糊 / 9px / 选中蓝）
struct DZTabBar: View {
    @Binding var sel: Int
    private let items: [(String, String, String)] = [
        ("bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill", "消息"),
        ("person.2", "person.2.fill", "通讯录"),
        ("person.crop.circle", "person.crop.circle.fill", "我"),
    ]
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(T.sepLine).frame(height: 0.5)
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    Button { sel = i } label: {
                        VStack(spacing: 4) {
                            Image(systemName: sel == i ? items[i].1 : items[i].0)
                                .font(.system(size: 19, weight: .regular))
                            Text(items[i].2).font(.system(size: 9, weight: sel == i ? .medium : .regular))
                        }
                        .foregroundColor(sel == i ? T.blue : T.tabIdle)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8).frame(height: 62, alignment: .top)
        }
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.55))
    }
}

/// 头像（效果图里的渐变圆 + 首字；在线右下绿点，离线去色）
struct Ava: View {
    let name: String
    var size: CGFloat = 46
    var online: Bool? = nil
    var img: String = ""
    private var hue: Double {
        var h = 0
        for u in name.unicodeScalars { h = (h &* 31 &+ Int(u.value)) % 360 }
        return Double(h) / 360
    }
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hue: hue, saturation: 0.40, brightness: 0.99),
                                                      Color(hue: hue, saturation: 0.62, brightness: 0.84)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(String(name.prefix(1))).font(.system(size: size * 0.4, weight: .semibold)).foregroundColor(.white)
                if !img.isEmpty, let u = URL(string: "https://bbji.xkmd.cn/api/file/\(img)") {
                    AsyncImage(url: u) { ph in
                        if let im = ph.image { im.resizable().scaledToFill() } else { Color.clear }
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .saturation(online == false ? 0 : 1)
            .opacity(online == false ? 0.5 : 1)
            if online == true {
                Circle().fill(T.green).frame(width: size * 0.3, height: size * 0.3)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.6))
            }
        }
        .frame(width: size, height: size)
    }
}
